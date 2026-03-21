import 'dart:nativewrappers/_internal/vm/lib/async_patch.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/camera_guidance_service.dart';
import '../services/tts_service.dart';
import '../services/haptic_service.dart';
import '../services/ml_kit_service.dart';
import '../services/voice_command_service.dart';
import '../widgets/zone_gesture_detector.dart';
import '../widgets/semantic_widgets.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final CameraGuidanceService _guidance = CameraGuidanceService();
  final AudioFeedbackManager _audio = AudioFeedbackManager();
  final HapticService _haptics = HapticService();
  final SceneDescriptionService _sceneService = SceneDescriptionService();
  final TextRecognitionService _textService = TextRecognitionService();
  final VoiceCommandService _voice = VoiceCommandService();

  // For holding the last recognized voice command to allow repeating it if needed
  String _lastHeard = "";
  Timer? _holdTimer;

  

  String _statusMessage = "Ready";
  double _speechRate = 0.5;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _guidance.stopMonitoring();
    _audio.stop();
    _haptics.stop();
    _textService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraService.controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _guidance.stopMonitoring();
    } else if (state == AppLifecycleState.resumed) {
      _guidance.startMonitoring(cameraController);
    }
  }

  Future<void> _initializeServices() async {
    if (_cameraService.controller == null ||
        !_cameraService.controller!.value.isInitialized) {
      await _cameraService.initializeCamera();
    }

    final controller = _cameraService.controller;
    if (controller != null && controller.value.isInitialized) {
      _guidance.startMonitoring(controller);

      await Future.delayed(const Duration(milliseconds: 500));
      await _audio.speak(
        "Accessibility Lens ready. Single tap to describe scene. Double tap to read text. Long press to repeat, Hold the microphone to speak a command, say Help for a list of commands.",
      );
      await _voice.init();
    } else {
      await _audio.speak("Camera not ready");
    }
  }

  Future<T> _withStreamPaused<T>(Future<T> Function() action) async {
    final controller = _cameraService.controller;
    final wasMonitoring = _guidance.isMonitoring;

    if (wasMonitoring) {
      _guidance.stopMonitoring();
      await Future.delayed(const Duration(milliseconds: 80));
    }

    try {
      return await action();
    } finally {
      if (wasMonitoring &&
          controller != null &&
          controller.value.isInitialized &&
          mounted) {
        _guidance.startMonitoring(controller);
      }
    }
  }

  Future<void> _handleSingleTap() async {
    if (_busy) return;
    _busy = true;

    final controller = _cameraService.controller;

    if (controller == null || !controller.value.isInitialized) {
      await _audio.speak("Camera not ready");
      _busy = false;
      return;
    }

    setState(() => _statusMessage = "Analyzing scene...");
    await _audio.announceDescribingScene();

    try {
      await _withStreamPaused(() async {
        final XFile photo = await controller.takePicture();
        final String description = await _sceneService.describeScene(
          photo.path,
        );

        _haptics.success();
        await _audio.speak(description);

        final file = File(photo.path);
        if (await file.exists()) await file.delete();
      });
    } catch (e) {
      await _audio.speak("Failed to analyze the scene.");
    } finally {
      if (mounted) setState(() => _statusMessage = "Ready");
      _busy = false;
    }
  }

  /// Double Tap: "What is this?" (Text Recognition)
  Future<void> _handleDoubleTap() async {
    if (_busy) return;
    _busy = true;

    final controller = _cameraService.controller;

    if (controller == null || !controller.value.isInitialized) {
      await _audio.speak("Camera not ready");
      _busy = false;
      return;
    }

    setState(() => _statusMessage = "Reading text...");
    await _audio.announceCapturingText();

    try {
      await _withStreamPaused(() async {
        final XFile photo = await controller.takePicture();
        final String extractedText = await _textService.processImage(
          photo.path,
        );

        if (extractedText.isEmpty) {
          await _audio.speak("No text detected in view.");
        } else {
          _haptics.success();
          await _audio.speak("The text says: $extractedText");
        }

        final file = File(photo.path);
        if (await file.exists()) await file.delete();
      });
    } catch (e) {
      await _audio.speak("Failed to process the image.");
    } finally {
      if (mounted) setState(() => _statusMessage = "Ready");
      _busy = false;
    }
  }

  Future<void> _handleLongPress() async {
    await _audio.repeatLast();
  }

  Future<void> _handleSwipeUp() async {
    setState(() {
      _speechRate = (_speechRate + 0.1).clamp(0.1, 0.9);
    });
    await _audio.setSpeechRate(_speechRate);
    await _audio.speak("Speech rate ${(_speechRate * 10).round()}");
  }

  Future<void> _handleSwipeDown() async {
    setState(() {
      _speechRate = (_speechRate - 0.1).clamp(0.1, 0.9);
    });
    await _audio.setSpeechRate(_speechRate);
    await _audio.speak("Speech rate ${(_speechRate * 10).round()}");
  }

  Future<void> _handleSwipeLeft() async {
    await _audio.disableTts();
    setState(() => _statusMessage = "TTS off");
  }

  Future<void> _handleSwipeRight() async {
    await _audio.enableTts();
    setState(() => _statusMessage = "TTS on");
    await _audio.speak("Speech on");
  }

  // Voice Command Execution
  Future<void> _onHoldToTalkStart() async {
    if (_busy) return;
    if (_voice.isListening) return;

    setState(() => _statusMessage = "Listening...");

    await _audio.enterListeningMode();

    await _voice.startHoldToTalk(
      onWords: (words, isFinal) {
        _lastHeard = words;

        if (isFinal) {
          Future.microtask(() => _executeVoiceCommand(words));
        }
      },
    );
  }

  Future<void> _onHoldToTalkEnd() async {
        if (!_voice.isListening){
          await _audio.exitListeningMode();
          if (mounted) setState(() => _statusMessage = "Ready");
          return;
    }

    await _voice.stopHoldToTalk();
    await _audio.exitListeningMode();

    if (mounted) setState(() => _statusMessage = "Ready");
  }

  // Voice Command Handling
  Future<void> _executeVoiceCommand(String words) async {
    final cmd = VoiceCommandParser.parse(words);

    switch (cmd) {
      // Capture Scene
      case VoiceCommand.captureScene:
        await _audio.stop(); // Stop any ongoing speech
        await _handleSingleTap();
        break;

      // Capture Text
      case VoiceCommand.captureText:
        await _audio.stop();
        await _handleDoubleTap();
        break;

      // Volume Up
      case VoiceCommand.volumeUp:
        final v = await VolumeController.instance.getVolume();
        await VolumeController.instance.setVolume((v + 0.1).clamp(0.0, 1.0));
        await _audio.speak("Volume up");
        break;

      // Volume Down
      case VoiceCommand.volumeDown:
        final v = await VolumeController.instance.getVolume();
        await VolumeController.instance.setVolume((v - 0.1).clamp(0.0, 1.0));
        await _audio.speak("Volume down");
        break;

      // Stop
      case VoiceCommand.stop:
        await _audio.stop();
        break;

      // Repeat
      case VoiceCommand.repeat:
        await _audio.repeatLast();
        break;

      // Adjust Speech Rate
      case VoiceCommand.speedUp:
        await _handleSwipeUp();
        break;
        
      case VoiceCommand.slowDown:
        await _handleSwipeDown();
        break;

      // Help
      case VoiceCommand.help:
        await _audio.speak(
          "Commands: Capture scene, Capture text, Volume up, Volume down, Stop, Force stop, Exit, Repeat, Help.",
        );
        break;

      // Exit
      case VoiceCommand.exit:
        // iOS generally discourages programmatic exit)
        await _audio.stop();
        await _audio.speak("Exiting");
        await Future.delayed(const Duration(milliseconds: 300));
        SystemNavigator.pop();
        break;

      // Force Stop: a safe approach is to stop speech, stop camera stream, and re-init services
      case VoiceCommand.forceStop:
        await _audio.stop();
        _guidance.stopMonitoring();
        _cameraService.dispose();
        await _audio.speak("Resetting");
        await Future.delayed(const Duration(milliseconds: 200));
        await _cameraService.initializeCamera();
        final controller = _cameraService.controller;
        if (controller != null && controller.value.isInitialized) {
          _guidance.startMonitoring(controller);
        }
        break;

      case VoiceCommand.unknown:
        // Ignore unknowns to avoid noisy feedback
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SemanticGestureZone(
        label: "Camera interface",
        hint:
            "Single tap describe scene, double tap read text, long press repeat, swipe up or down change speed, swipe left speech off, swipe right speech on, hold the microphone to speak a command, say help for a list of commands.",
        child: ZoneGestureDetector(
          onSingleTap: _handleSingleTap,
          onDoubleTap: _handleDoubleTap,
          onLongPress: _handleLongPress,
          onSwipeUp: _handleSwipeUp,
          onSwipeDown: _handleSwipeDown,
          onSwipeLeft: _handleSwipeLeft,
          onSwipeRight: _handleSwipeRight,
          child: Stack(
            children: [
              _buildCameraPreview(),
              _buildStatusIndicator(),
              Positioned(
                top: 0,
                left: 0,
                child: LiveRegionAnnouncer(message: _statusMessage),
              ),
              // Voice Command Button
              Positioned(
                right: 20,
                bottom: 40,
                child: ExcludeSemantics(
                  child: Listener(
                    onPointerDown: (_) => _onHoldToTalkStart(),
                    onPointerUp: (_) => _onHoldToTalkEnd(),
                    onPointerCancel: (_) => _onHoldToTalkEnd(),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        _voice.isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _cameraService.controller;

    if (controller == null || !controller.value.isInitialized) {
      return const SemanticCameraView(
        statusMessage: "Initializing camera",
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return SemanticCameraView(
      statusMessage: _getCameraStatusMessage(),
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize!.height,
            height: controller.value.previewSize!.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.only(
            bottom: bottomPadding + 20,
            top: 30,
            left: 30,
            right: 30,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
            ),
          ),
          child: Column(
            children: [
              Icon(_getStatusIcon(), color: _getStatusColor(), size: 32),
              const SizedBox(height: 12),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getCameraQualityMessage(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCameraStatusMessage() {
    switch (_guidance.currentState) {
      case CameraQualityState.lensBlocked:
        return "Camera lens is blocked";
      case CameraQualityState.toDark:
        return "Lighting is too dark";
      case CameraQualityState.good:
        return "Camera ready with good lighting";
      case CameraQualityState.acceptable:
        return "Camera ready";
      default:
        return "Camera active";
    }
  }

  IconData _getStatusIcon() {
    switch (_guidance.currentState) {
      case CameraQualityState.lensBlocked:
        return Icons.block;
      case CameraQualityState.toDark:
        return Icons.lightbulb_outline;
      case CameraQualityState.good:
        return Icons.check_circle;
      default:
        return Icons.camera_alt;
    }
  }

  Color _getStatusColor() {
    switch (_guidance.currentState) {
      case CameraQualityState.lensBlocked:
        return Colors.red;
      case CameraQualityState.toDark:
        return Colors.orange;
      case CameraQualityState.good:
        return Colors.green;
      default:
        return Colors.white;
    }
  }

  String _getCameraQualityMessage() {
    if (_audio.isSpeaking) return "Speaking...";
    if (_audio.isListening) return "Listening...";

    switch (_guidance.currentState) {
      case CameraQualityState.lensBlocked:
        return "Uncover the camera lens";
      case CameraQualityState.toDark:
        return "Move to a brighter area";
      case CameraQualityState.good:
        return "Optimal conditions";
      default:
        return "Tap anywhere to interact";
    }
  }
}
