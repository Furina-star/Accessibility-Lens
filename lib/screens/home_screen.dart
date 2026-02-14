import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/haptic_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CameraService _cameraService = CameraService();
  final HapticService _hapticService = HapticService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Location-Independent Gestures (Objective B)
        onTap: () async {
          _hapticService.triggerDucking(true);
          _hapticService.heartbeat();
          print("Command Triggered: Describe Scene");

          // Simulation of AI processing time
          await Future.delayed(Duration(seconds: 3));

          _hapticService.stop();
          _hapticService.triggerDucking(false);
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: (_cameraService.controller != null && _cameraService.controller!.value.isInitialized)
              ? CameraPreview(_cameraService.controller!)
              : Center(child: Text("Initializing Camera...", style: TextStyle(color: Colors.white))),
        ),
      ),
    );
  }
}