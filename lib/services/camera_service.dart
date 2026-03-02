import 'package:camera/camera.dart';
import 'haptic_service.dart';
import 'dart:io';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? controller;
  final HapticService haptics = HapticService();

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print("No cameras found on this device.");
        return;
      }

      final backCamera = cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await controller!.initialize();
      await controller!.setFocusMode(FocusMode.auto);
    } catch (e) {
      print("Camera Initialization Error: $e");
    }
  }

  void dispose() {
    controller?.dispose();
    controller = null;
  }
}