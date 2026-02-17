import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/home_screen.dart';
import 'services/camera_service.dart';

// We make main 'async' because we have to wait for the camera hardware to wake up
Future<void> main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Get the list of available cameras on the device
    final cameras = await availableCameras();

    // 3. Set up the camera in your Service so the UI can see it
    if (cameras.isNotEmpty) {
      CameraService().controller = CameraController(
        cameras.first, // Usually the back camera
        ResolutionPreset.high,
        enableAudio: false, // Prevents feedback loops from the start
      );

      // Initialize the controller
      await CameraService().controller!.initialize();

      // Note: Camera monitoring is now started by CameraGuidanceService
      // in HomeScreen's initState, not here
    }
  } catch (e) {
    print("Camera initialization error: $e");
  }

  // 4. Run the actual App
  runApp(const AccessibilityLensApp());
}

class AccessibilityLensApp extends StatelessWidget {
  const AccessibilityLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accessibility Lens',
      debugShowCheckedModeBanner: false, // Clean UI for BVI users
      theme: ThemeData(
        brightness: Brightness.dark, // Better for battery and some low-vision users
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(), // Points to your home_screen.dart
    );
  }
}