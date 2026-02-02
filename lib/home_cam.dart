import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Camera
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  // State
  bool _isProcessing = false;
  String _result = "Tap the button to scan";
  ScanMode _selectedMode = ScanMode.auto;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _requestPermissions();
    await _initializeCamera();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.camera.request();

    if (status.isDenied) {
      setState(() {
        _result = "Camera permission is required to use this app.";
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _result = "No camera found on this device.";
        });
        return;
      }

      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _result = "Error initializing camera: $e";
      });
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _result = "Analyzing...";
    });

    try {
      // Capture image
      final XFile image = await _cameraController!.takePicture();

      // Future Development like Commands and stuff yeah etc etc
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _result = "Image captured successfully!\nPath: ${image.path}\n\n(Coming Soon)";
      });

    } catch (e) {
      setState(() {
        _result = "Error capturing image: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: _buildCameraPreview(),
              ),
            ),
          ),

          // Mode Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ScanMode.values.map((mode) {
                return _buildModeButton(mode);
              }).toList(),
            ),
          ),

          // Result Display
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _result,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.onSurface,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Scan Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 70,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _captureAndAnalyze,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isProcessing
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('ANALYZING...'),
                  ],
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 28),
                    SizedBox(width: 12),
                    Text('SCAN', style: TextStyle(fontSize: 22)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return CameraPreview(_cameraController!);
  }

  Widget _buildModeButton(ScanMode mode) {
    final isSelected = _selectedMode == mode;

    IconData icon;
    switch (mode) {
      case ScanMode.auto:
        icon = Icons.auto_awesome;
        break;
      case ScanMode.text:
        icon = Icons.text_fields;
        break;
      case ScanMode.object:
        icon = Icons.category;
        break;
      case ScanMode.barcode:
        icon = Icons.qr_code;
        break;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[600]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              mode.displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}