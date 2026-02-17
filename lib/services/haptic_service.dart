import 'package:vibration/vibration.dart';

/// Comprehensive Haptic Language System
/// Provides a tactile "vocabulary" for blind users
class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _isVibrating = false;

  // ==================== HAPTIC VOCABULARY ====================

  /// Success: One short, sharp pulse
  void success() {
    _isVibrating = true;
    Vibration.vibrate(duration: 100, amplitude: 255);
    Future.delayed(Duration(milliseconds: 100), () => _isVibrating = false);
  }

  /// Error/Warning: Three rapid, heavy pulses
  void error() {
    _isVibrating = true;
    Vibration.vibrate(
      pattern: [0, 150, 100, 150, 100, 150],
      intensities: [0, 255, 0, 255, 0, 255],
    );
    Future.delayed(Duration(milliseconds: 550), () => _isVibrating = false);
  }

  /// Processing/Loading: Continuous light heartbeat pulse
  void heartbeat() {
    _isVibrating = true;
    Vibration.vibrate(
      pattern: [0, 100, 800],
      repeat: 0, // Continuous
    );
  }

  /// Text Detected: High-pitched "ding" simulation (short double-tap)
  void textDetected() {
    _isVibrating = true;
    Vibration.vibrate(
      pattern: [0, 50, 100, 50],
      intensities: [0, 200, 0, 200],
    );
    Future.delayed(Duration(milliseconds: 200), () => _isVibrating = false);
  }

  /// Camera Too Dark: Continuous heavy pulse
  void cameraToDark() {
    _isVibrating = true;
    Vibration.vibrate(
      pattern: [0, 500, 500],
      repeat: 0,
      amplitude: 255,
    );
  }

  /// Camera Blurry: Specific pulsing pattern
  void cameraBlurry() {
    _isVibrating = true;
    Vibration.vibrate(
      pattern: [0, 200, 200, 200, 200],
      repeat: 0,
      amplitude: 180,
    );
  }

  /// Lens Blocked: Urgent alert
  void lensBlockedAlert() {
    _isVibrating = true;
    Vibration.vibrate(
      pattern: [0, 500, 100, 500, 100, 500],
      intensities: [0, 255, 0, 255, 0, 255],
    );
    Future.delayed(Duration(milliseconds: 1600), () => _isVibrating = false);
  }

  /// Low Light Warning: Gentle repeating pulse
  void lowLightWarning() {
    _isVibrating = true;
    Vibration.vibrate(
      pattern: [0, 300, 700],
      repeat: 0,
      amplitude: 150,
    );
  }

  /// Listening Mode Active: Heart-like pulse
  void listeningPulse() {
    _isVibrating = true;
    Vibration.vibrate(
      pattern: [0, 100, 150, 100, 600],
      repeat: 0,
    );
  }

  /// Button/Zone Activated: Light tap confirmation
  void lightTap() {
    Vibration.vibrate(duration: 30, amplitude: 128);
  }

  /// Medium feedback
  void mediumTap() {
    Vibration.vibrate(duration: 50, amplitude: 180);
  }

  /// Heavy feedback
  void heavyTap() {
    Vibration.vibrate(duration: 100, amplitude: 255);
  }

  /// Stop all vibrations
  void stop() {
    _isVibrating = false;
    Vibration.cancel();
  }

  bool get isVibrating => _isVibrating;
}