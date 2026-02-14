import 'package:camera/camera.dart';
import 'haptic_service.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? controller;
  // Make this public so HomeScreen can access it
  final HapticService haptics = HapticService();

  void startProactiveMonitor() {
    controller?.startImageStream((CameraImage image) {
      final bytes = image.planes[0].bytes;
      double avgBrightness = bytes.reduce((a, b) => a + b) / bytes.length;

      if (avgBrightness < 15) {
        haptics.lensBlockedAlert();
      } else if (avgBrightness < 45) {
        haptics.lowLightWarning();
      } else {
        haptics.stop();
      }
    });
  }
}