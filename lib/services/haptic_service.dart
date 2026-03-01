import 'package:vibration/vibration.dart';

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _isVibrating = false;

  void success() {
    _isVibrating = true;
    Vibration.vibrate(duration: 100, amplitude: 255);
    Future.delayed(const Duration(milliseconds: 100), () => _isVibrating = false);
  }

  void error() {
    _isVibrating = true;
    Vibration.vibrate(
      pattern: [0, 150, 100, 150, 100, 150],
      intensities: [0, 255, 0, 255, 0, 255],
    );
    Future.delayed(const Duration(milliseconds: 550), () => _isVibrating = false);
  }

  void heartbeat() {
    _isVibrating = true;
    Vibration.vibrate(
      pattern: [0, 100, 800],
      repeat: 0,
    );
  }

  void textDetected() {
    _isVibrating = true;
    Vibration.vibrate(
      pattern: [0, 50, 100, 50],
      intensities: [0, 200, 0, 200],
    );
    Future.delayed(const Duration(milliseconds: 200), () => _isVibrating = false);
  }

  void cameraTooDark() {
    _isVibrating = true;
    Vibration.vibrate(
      pattern: [0, 500, 500],
      repeat: 0,
      amplitude: 255,
    );
  }

  void cameraBlurry() {
    _isVibrating = true;
    Vibration.vibrate(
      pattern: [0, 200, 200, 200, 200],
      repeat: 0,
      amplitude: 180,
    );
  }

  void lensBlockedAlert() {
    _isVibrating = true;
    Vibration.vibrate(
      pattern: [0, 500, 100, 500, 100, 500],
      intensities: [0, 255, 0, 255, 0, 255],
    );
    Future.delayed(const Duration(milliseconds: 1600), () => _isVibrating = false);
  }

  void lowLightWarning() {
    _isVibrating = true;
    Vibration.vibrate(
      pattern: [0, 300, 700],
      repeat: 0,
      amplitude: 150,
    );
  }

  void listeningPulse() {
    _isVibrating = true;
    Vibration.vibrate(
      pattern: [0, 100, 150, 100, 600],
      repeat: 0,
    );
  }

  void lightTap() {
    Vibration.vibrate(duration: 30, amplitude: 128);
  }

  void mediumTap() {
    Vibration.vibrate(duration: 50, amplitude: 180);
  }

  void heavyTap() {
    Vibration.vibrate(duration: 100, amplitude: 255);
  }

  void stop() {
    _isVibrating = false;
    Vibration.cancel();
  }

  bool get isVibrating => _isVibrating;
}