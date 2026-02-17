import 'package:camera/camera.dart';
import 'haptic_service.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? controller;
  final HapticService haptics = HapticService();

// Note: Proactive monitoring is now handled by CameraGuidanceService
// This class focuses solely on camera controller management
}