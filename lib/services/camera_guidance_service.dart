import 'package:camera/camera.dart';
import 'tts_service.dart'; // Uses your existing file name
import 'haptic_service.dart';

/// Camera Feedback System
/// Provides real-time guidance to help blind users position the camera correctly
class CameraGuidanceService {
  static final CameraGuidanceService _instance = CameraGuidanceService._internal();
  factory CameraGuidanceService() => _instance;
  CameraGuidanceService._internal();

  final AudioFeedbackManager _audio = AudioFeedbackManager();
  final HapticService _haptics = HapticService();

  CameraController? _controller;
  bool _isMonitoring = false;

  // Thresholds for guidance
  static const double VERY_DARK_THRESHOLD = 15.0;
  static const double LOW_LIGHT_THRESHOLD = 45.0;
  static const double GOOD_LIGHT_THRESHOLD = 80.0;

  CameraQualityState _lastState = CameraQualityState.unknown;
  DateTime? _lastAnnouncementTime;
  static const Duration ANNOUNCEMENT_COOLDOWN = Duration(seconds: 3);

  // ==================== MONITORING ====================

  void startMonitoring(CameraController controller) {
    _controller = controller;
    _isMonitoring = true;

    _controller?.startImageStream((CameraImage image) {
      if (!_isMonitoring) return;

      _analyzeImage(image);
    });
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _controller?.stopImageStream();
    _haptics.stop();
  }

  void _analyzeImage(CameraImage image) {
    // Calculate average brightness
    final bytes = image.planes[0].bytes;
    double avgBrightness = bytes.reduce((a, b) => a + b) / bytes.length;

    // Determine camera quality state
    CameraQualityState newState = _determineState(avgBrightness);

    // Only announce if state changed and cooldown has passed
    if (newState != _lastState) {
      if (_shouldAnnounce()) {
        _announceState(newState);
        _lastAnnouncementTime = DateTime.now();
      }
      _lastState = newState;
    }

    // Update haptic feedback continuously
    _updateHapticFeedback(newState);
  }

  CameraQualityState _determineState(double brightness) {
    if (brightness < VERY_DARK_THRESHOLD) {
      return CameraQualityState.lensBlocked;
    } else if (brightness < LOW_LIGHT_THRESHOLD) {
      return CameraQualityState.toDark;
    } else if (brightness >= GOOD_LIGHT_THRESHOLD) {
      return CameraQualityState.good;
    } else {
      return CameraQualityState.acceptable;
    }
  }

  bool _shouldAnnounce() {
    if (_lastAnnouncementTime == null) return true;
    return DateTime.now().difference(_lastAnnouncementTime!) > ANNOUNCEMENT_COOLDOWN;
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
      // Don't announce - just provide haptic feedback
        _haptics.stop();
        break;
      case CameraQualityState.unknown:
        break;
    }
  }

  void _updateHapticFeedback(CameraQualityState state) {
    switch (state) {
      case CameraQualityState.lensBlocked:
        if (!_haptics.isVibrating) {
          _haptics.lensBlockedAlert();
        }
        break;
      case CameraQualityState.toDark:
        if (!_haptics.isVibrating) {
          _haptics.cameraToDark();
        }
        break;
      case CameraQualityState.good:
      case CameraQualityState.acceptable:
        _haptics.stop();
        break;
      case CameraQualityState.unknown:
        break;
    }
  }

  // ==================== GETTERS ====================

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