import 'package:flutter/material.dart';
import 'services/camera_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the cameras into our service
  await CameraService.initialize();

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomeScreen(),
  ));
}