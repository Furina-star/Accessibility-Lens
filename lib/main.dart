import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/camera_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// We make main 'async' because we have to wait for the camera hardware to wake up
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  try {
    await CameraService().initializeCamera();
  } catch (e) {
    print("Camera initialization error: $e");
    // Note: If the camera fails (e.g., user denied permissions), the app will still
    // launch, but your HomeScreen's error handlers will catch the missing controller!
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