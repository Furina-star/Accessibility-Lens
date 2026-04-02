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

  bool _ttsEnabled = true;

  double _originalVolume = 1.0;
  bool _hasCapturedOriginal = false;
  bool _isAdjusted = false;

  String _lastSpokenMessage = "";

  static const double _listeningVolumeFactor = 0.2; // volume down when user speaks
  static const double _ttsVolumeBoostFactor = 1.0;  // volume up when TTS speaks
  static const double _minListeningVolume = 0.05;
  static const double _maxListeningVolume = 0.25;

  static const double _minTtsVolume = 0.60;
  static const double _maxTtsVolume = 1.00;

  Future<void> _initializeTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() async {
      _isSpeaking = false;
      if (!_isListening) await _restoreVolumeIfNeeded();
    });

    _tts.setCancelHandler(() async {
      _isSpeaking = false;
      if (!_isListening) await _restoreVolumeIfNeeded();
    });

    _tts.setErrorHandler((msg) async {
      _isSpeaking = false;
      _haptics.error();
      print("TTS Error: $msg");
      if (!_isListening) await _restoreVolumeIfNeeded();
    });
  }

  Future<void> setSpeechRate(double rate) async {
    final clamped = rate.clamp(0.1, 0.9);
    await _tts.setSpeechRate(clamped);
  }

  Future<List<Map<String, String>>> getAvailableVoices() async {
    final voices = await _tts.getVoices;
    final list = <Map<String, String>>[];

    for (final v in voices) {
      if (v is Map) {
        final name = v['name']?.toString();
        final locale = v['locale']?.toString();
        if (name != null && locale != null) {
          list.add({'name': name, 'locale': locale});
        }
      }
    }

    list.sort((a, b) {
      final la = a['locale'] ?? '';
      final lb = b['locale'] ?? '';
      final na = a['name'] ?? '';
      final nb = b['name'] ?? '';
      final c = la.compareTo(lb);
      return c != 0 ? c : na.compareTo(nb);
    });

    return list;
  }

  Future<void> setVoiceByNameAndLocale({
    required String name,
    required String locale,
  }) async {
    await _tts.setVoice({'name': name, 'locale': locale});
  }

  Future<void> setPitch(double pitch) async {
    final clamped = pitch.clamp(0.5, 2.0);
    await _tts.setPitch(clamped);
  }

  bool get ttsEnabled => _ttsEnabled;

  Future<void> enableTts() async {
    _ttsEnabled = true;
    _haptics.lightTap();
  }

  Future<void> disableTts() async {
    _ttsEnabled = false;
    await stop();
    _haptics.heavyTap();
  }

  Future<void> toggleTts() async {
    if (_ttsEnabled) {
      await disableTts();
    } else {
      await enableTts();
    }
  }

  Future<void> _captureOriginalVolumeIfNeeded() async {
    if (_hasCapturedOriginal) return;
    _originalVolume = await VolumeController.instance.getVolume();
    _hasCapturedOriginal = true;
  }

  Future<void> _setInputVolumeForListening() async {
    await _captureOriginalVolumeIfNeeded();

    final lowered = (_originalVolume * _listeningVolumeFactor)
        .clamp(_minListeningVolume, _maxListeningVolume);

    await VolumeController.instance.setVolume(lowered);
    _isAdjusted = true;
  }

  Future<void> _setOutputVolumeForTts() async {
    await _captureOriginalVolumeIfNeeded();

    // tts volume up after magprompt
    final boosted = (_originalVolume * _ttsVolumeBoostFactor)
        .clamp(_minTtsVolume, _maxTtsVolume);

    await VolumeController.instance.setVolume(boosted);
    _isAdjusted = true;
  }

  Future<void> _restoreVolumeIfNeeded() async {
    if (!_isAdjusted) return;
    if (!_hasCapturedOriginal) return;

    await VolumeController.instance.setVolume(_originalVolume);

    _isAdjusted = false;
    _hasCapturedOriginal = false;
  }

  Future<void> mute() async {
    await _captureOriginalVolumeIfNeeded();
    await VolumeController.instance.setVolume(0.0);
    _isAdjusted = true;

    await _tts.stop();
    _isSpeaking = false;
  }

  Future<void> speak(String message, {bool withHaptic = true}) async {
    if (!_ttsEnabled) {
      if (withHaptic) _haptics.lightTap();
      _lastSpokenMessage = message;
      return;
    }

    if (_isSpeaking) {
      await _tts.stop();
    }

    _lastSpokenMessage = message;
    _isSpeaking = true;

    if (withHaptic) _haptics.mediumTap();

    await _setOutputVolumeForTts();
    await _tts.speak(message);
  }

  Future<void> speakUrgent(String message) async {
    if (!_ttsEnabled) {
      _haptics.heavyTap();
      _lastSpokenMessage = message;
      return;
    }

    await _tts.stop();
    _haptics.heavyTap();
    _isSpeaking = true;

    await _setOutputVolumeForTts();
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
    await _tts.stop();
    _isSpeaking = false;

    await _setInputVolumeForListening();
  }

  Future<void> exitListeningMode() async {
    _isListening = false;
    _haptics.stop();
    await _restoreVolumeIfNeeded();
  }

  Future<void> announceSingleTap() async => _haptics.lightTap();
  Future<void> announceDoubleTap() async => _haptics.mediumTap();
  Future<void> announceLongPress() async => _haptics.heavyTap();

  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
    if (!_isListening) await _restoreVolumeIfNeeded();
  }

  Future<void> dispose() async {
    await stop();
    _haptics.stop();
    await _restoreVolumeIfNeeded();
  }
}