import 'package:camera/camera.dart';
import 'tts_service.dart';
import 'haptic_service.dart';

class CameraGuidanceService {
  static final CameraGuidanceService _instance = CameraGuidanceService._internal();
  factory CameraGuidanceService() => _instance;
  CameraGuidanceService._internal();

  final AudioFeedbackManager _audio = AudioFeedbackManager();
  final HapticService _haptics = HapticService();

  CameraController? _controller;
  bool _isMonitoring = false;
  bool _isStreamActive = false;

  static const double veryDarkThreshold = 15.0;
  static const double lowLightThreshold = 45.0;
  static const double goodLightThreshold = 80.0;

  CameraQualityState _lastState = CameraQualityState.unknown;
  DateTime? _lastAnnouncementTime;
  static const Duration announcementCoolDown = Duration(seconds: 3);

  void startMonitoring(CameraController controller) {
    _controller = controller;
    _isMonitoring = true;

    if (_isStreamActive) return;

    try {
      _controller?.startImageStream((CameraImage image) {
        if (!_isMonitoring) return;
        _analyzeImage(image);
      });
      _isStreamActive = true;
    } catch (_) {
      _isStreamActive = false;
    }
  }

  void stopMonitoring() {
    _isMonitoring = false;

    final c = _controller;
    if (c != null && _isStreamActive) {
      try {
        c.stopImageStream();
      } catch (_) {}
    }

    _isStreamActive = false;
    _haptics.stop();
  }

  void _analyzeImage(CameraImage image) {
    if (image.planes.isEmpty) return;

    final bytes = image.planes[0].bytes;
    if (bytes.isEmpty) return;

    final int sampleStep = (bytes.length ~/ 5000).clamp(1, 1000);
    int sum = 0;
    int count = 0;

    for (int i = 0; i < bytes.length; i += sampleStep) {
      sum += bytes[i];
      count++;
    }

    final double avgBrightness = sum / count;

    CameraQualityState newState = _determineState(avgBrightness);

    if (newState != _lastState) {
      if (_shouldAnnounce()) {
        _announceState(newState);
        _lastAnnouncementTime = DateTime.now();
      }
      _lastState = newState;
    }

    _updateHapticFeedback(newState);
  }

  CameraQualityState _determineState(double brightness) {
    if (brightness < veryDarkThreshold) {
      return CameraQualityState.lensBlocked;
    } else if (brightness < lowLightThreshold) {
      return CameraQualityState.toDark;
    } else if (brightness >= goodLightThreshold) {
      return CameraQualityState.good;
    } else {
      return CameraQualityState.acceptable;
    }
  }

  bool _shouldAnnounce() {
    if (_lastAnnouncementTime == null) return true;
    return DateTime.now().difference(_lastAnnouncementTime!) > announcementCoolDown;
  }

  void _announceState(CameraQualityState state) {
    switch (state) {
      case CameraQualityState.lensBlocked:
        _audio.announceLensBlocked();
        break;
      case CameraQualityState.toDark:
        _audio.announceCameraToDark();
        break;
      case CameraQualityState.good:
        _audio.announceGoodLighting();
        break;
      case CameraQualityState.acceptable:
        _haptics.stop();
        break;
      case CameraQualityState.unknown:
        break;
    }
  }

  void _updateHapticFeedback(CameraQualityState state) {
    switch (state) {
      case CameraQualityState.lensBlocked:
        if (!_haptics.isVibrating) _haptics.lensBlockedAlert();
        break;
      case CameraQualityState.toDark:
        if (!_haptics.isVibrating) _haptics.cameraTooDark();
        break;
      case CameraQualityState.good:
      case CameraQualityState.acceptable:
        if (_haptics.isVibrating) _haptics.stop();
        break;
      case CameraQualityState.unknown:
        break;
    }
  }

  CameraQualityState get currentState => _lastState;
  bool get isMonitoring => _isMonitoring;
}

enum CameraQualityState {
  unknown,
  lensBlocked,
  toDark,
  acceptable,
  good,
}