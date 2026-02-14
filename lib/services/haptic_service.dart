import 'package:vibration/vibration.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:volume_controller/volume_controller.dart'; //

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  final FlutterTts _tts = FlutterTts();

  void triggerDucking(bool active) {
    if (active) {
      // Use the static instance instead of a constructor
      VolumeController.instance.setVolume(0.2);
    } else {
      VolumeController.instance.setVolume(0.7);
    }
  }

  void lowLightWarning() => Vibration.vibrate(duration: 500);

  void lensBlockedAlert() {
    Vibration.vibrate(pattern: [0, 500, 100, 500]);
    _tts.speak("Lens covered");
  }

  void heartbeat() => Vibration.vibrate(pattern: [0, 100, 800], repeat: 0);

  void stop() => Vibration.cancel();
}