import 'package:flutter_tts/flutter_tts.dart';
import 'package:volume_controller/volume_controller.dart';
import 'haptic_service.dart';

class AudioFeedbackManager {
  static final AudioFeedbackManager _instance = AudioFeedbackManager._internal();
  factory AudioFeedbackManager() => _instance;
  AudioFeedbackManager._internal() {
    _initializeTTS();
  }

  final FlutterTts _tts = FlutterTts();
  final HapticService _haptics = HapticService();

  bool _isSpeaking = false;
  bool _isListening = false;
  double _originalVolume = 1;
  String _lastSpokenMessage = "";

  Future<void> _initializeTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      if (!_isListening) {
        _restoreVolume();
      }
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      _haptics.error();
      print("TTS Error: $msg");
    });
  }

  Future<void> setSpeechRate(double rate) async {
    // keep it sane
    final clamped = rate.clamp(0.1, 0.9);
    await _tts.setSpeechRate(clamped);
  }

  Future<void> _duckAudio() async {
    _originalVolume = await VolumeController.instance.getVolume();
    await VolumeController.instance.setVolume(0.1);
  }

  Future<void> _restoreVolume() async {
    await VolumeController.instance.setVolume(_originalVolume);
  }

  Future<void> mute() async {
    _originalVolume = await VolumeController.instance.getVolume();
    await VolumeController.instance.setVolume(0.0);
    await _tts.stop();
    _isSpeaking = false;
  }

  Future<void> speak(String message, {bool withHaptic = true}) async {
    if (_isSpeaking) {
      await _tts.stop();
    }

    _lastSpokenMessage = message;
    _isSpeaking = true;

    if (withHaptic) {
      _haptics.mediumTap();
    }

    await _tts.speak(message);
  }

  Future<void> speakUrgent(String message) async {
    await _tts.stop();
    _haptics.heavyTap();
    _isSpeaking = true;
    await _tts.speak(message);
  }

  Future<void> repeatLast() async {
    if (_lastSpokenMessage.isNotEmpty) {
      _haptics.lightTap();
      await speak(_lastSpokenMessage, withHaptic: false);
    } else {
      await speak("Nothing to repeat");
    }
  }

  Future<void> announceCapturingText() async {
    await speak("Capturing text");
    _haptics.heartbeat();
  }

  Future<void> announceDescribingScene() async {
    await speak("Describing scene");
    _haptics.heartbeat();
  }

  Future<void> announceProcessing() async {
    await speak("Processing");
    _haptics.heartbeat();
  }

  Future<void> announceSuccess() async {
    _haptics.success();
    await speak("Success");
  }

  Future<void> announceError(String errorMessage) async {
    _haptics.error();
    await speak("Error: $errorMessage");
  }

  Future<void> announceCameraToDark() async {
    _haptics.cameraTooDark();
    await speakUrgent("It is too dark. Please turn on a light or move to a brighter area.");
  }

  Future<void> announceCameraBlurry() async {
    _haptics.cameraBlurry();
    await speakUrgent("Camera is blurry. Please hold still.");
  }

  Future<void> announceLensBlocked() async {
    _haptics.lensBlockedAlert();
    await speakUrgent("Lens is covered. Please uncover the camera.");
  }

  Future<void> announceGoodLighting() async {
    _haptics.success();
    await speak("Good lighting detected");
  }

  Future<void> announceTextInView() async {
    _haptics.textDetected();
    await speak("Text detected. Double tap to read.");
  }

  Future<void> enterListeningMode() async {
    _isListening = true;
    await mute();
    _haptics.listeningPulse();
  }

  Future<void> exitListeningMode() async {
    _isListening = false;
    _haptics.stop();
    await _restoreVolume();
  }

  Future<void> announceSingleTap() async {
    _haptics.lightTap();
  }

  Future<void> announceDoubleTap() async {
    _haptics.mediumTap();
  }

  Future<void> announceLongPress() async {
    _haptics.heavyTap();
  }

  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  Future<void> dispose() async {
    await _tts.stop();
    _haptics.stop();
    await _restoreVolume();
  }
}