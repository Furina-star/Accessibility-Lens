import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/camera_guidance_service.dart';
import '../services/tts_service.dart'; // Changed from audio_feedback_manager
import '../services/haptic_service.dart';
import '../services/ml_kit_service.dart';
import '../widgets/zone_gesture_detector.dart';
import '../widgets/semantic_widgets.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
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
  //final BarcodeService _barcodeService = BarcodeService();

  String _statusMessage = "Ready";
  double _speechRate = 0.5;
  /*
  bool _isProcessing = false;
  String _lastScannedBarcode = "";
  DateTime? _lastScanTime;
  */


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
    _audio.dispose();
    _haptics.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraService.controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _guidance.stopMonitoring();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameraService.controller != null) {
        _guidance.startMonitoring(_cameraService.controller!);
      }
    }
  }

  /// Stops the live stream to prevent camera crashes and save battery
  void _stopContinuousScanner() {
    final controller = _cameraService.controller;
    if (controller != null && controller.value.isStreamingImages) {
      controller.stopImageStream();
    }
  }

  Future<void> _initializeServices() async {
    // Start camera guidance
    if (_cameraService.controller != null &&
        _cameraService.controller!.value.isInitialized) {
      _guidance.startMonitoring(_cameraService.controller!);

      // Welcome message
      await Future.delayed(Duration(milliseconds: 500));
      await _audio.speak("Accessibility Lens ready. Single tap to describe scene. Double tap to read text. Long press to repeat.");
    }
  }

  // ==================== GESTURE HANDLERS ====================

  /// Single Tap: "What is this?" (Scene Description)
  Future<void> _handleSingleTap() async {
    final controller = _cameraService.controller;

    if (controller == null || !controller.value.isInitialized) {
      await _audio.speak("Camera not ready");
      return;
    }

    if (controller.value.isStreamingImages) {
      _stopContinuousScanner();
    }

    setState(() => _statusMessage = "Analyzing scene...");
    await _audio.announceDescribingScene();

    try {
      final XFile photo = await controller.takePicture();
      String description = await _sceneService.describeScene(photo.path);
      _haptics.success();
      await _audio.speak(description);

      await File(photo.path).delete();

    } catch (e) {
      print("Single Tap Error: $e");
      await _audio.speak("Failed to analyze the scene.");
    } finally {
      setState(() => _statusMessage = "Ready");
    }
  }

  Future<void> _handleDoubleTap() async {
    final controller = _cameraService.controller;

    if (controller == null || !controller.value.isInitialized) {
      await _audio.speak("Camera not ready");
      return;
    }

    if (controller.value.isStreamingImages) {
      _stopContinuousScanner();
    }

    setState(() => _statusMessage = "Reading text...");
    await _audio.announceCapturingText();

    try {
      final XFile photo = await controller.takePicture();
      String extractedText = await _textService.processImage(photo.path);

      if (extractedText.isEmpty) {
        await _audio.speak("No text detected in view.");
      } else {
        _haptics.success();
        await _audio.speak(extractedText);
      }

      final file = File(photo.path);
      if (await file.exists()) {
        await file.delete();
      }

    } catch (e) {
      print("Double Tap Error: $e");
      await _audio.speak("Failed to process the image.");
    } finally {
      setState(() => _statusMessage = "Ready");
    }
  }

  /// Long Press: Repeat last message
  Future<void> _handleLongPress() async {
    await _audio.repeatLast();
  }

  /// Swipe Up: Increase speech rate
  Future<void> _handleSwipeUp() async {
    setState(() {
      _speechRate = (_speechRate + 0.1).clamp(0.1, 0.9);
    });
    await _audio.speak("Speech rate increased to ${(_speechRate * 10).round()}");
  }

  /// Swipe Down: Decrease speech rate
  Future<void> _handleSwipeDown() async {
    setState(() {
      _speechRate = (_speechRate - 0.1).clamp(0.1, 0.9);
    });
    await _audio.speak("Speech rate decreased to ${(_speechRate * 10).round()}");
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SemanticGestureZone(
        label: "Camera interface",
        hint: "Single tap to describe scene, double tap to read text, long press to repeat, swipe up or down to adjust speed",
        child: ZoneGestureDetector(
          onSingleTap: _handleSingleTap,
          onDoubleTap: _handleDoubleTap,
          onLongPress: _handleLongPress,
          onSwipeUp: _handleSwipeUp,
          onSwipeDown: _handleSwipeDown,
          child: Stack(
            children: [
              // Camera Preview
              _buildCameraPreview(),

              // Status Indicator (for sighted helpers/developers)
              _buildStatusIndicator(),

              // Live region for screen reader announcements
              Positioned(
                top: 0,
                left: 0,
                child: LiveRegionAnnouncer(message: _statusMessage),
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
      return SemanticCameraView(
        statusMessage: "Initializing camera",
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
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
    // Visual indicator for developers and sighted helpers
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
              right: 30
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8), // Fixed deprecation
              ],
            ),
          ),
          child: Column(
            children: [
              Icon(
                _getStatusIcon(),
                color: _getStatusColor(),
                size: 32,
              ),
              SizedBox(height: 12),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _getCameraQualityMessage(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
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
        return "Please uncover the camera lens";
      case CameraQualityState.toDark:
        return "Move to a brighter area";
      case CameraQualityState.good:
        return "Optimal conditions";
      default:
        return "Tap anywhere to interact";
    }
  }

}
