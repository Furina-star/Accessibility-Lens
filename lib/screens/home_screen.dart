import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/haptic_service.dart';
import '../services/camera_service.dart';
import '../widgets/overlay_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? controller;

  @override
  void initState() {
    super.initState();
    if (CameraService.cameras.isNotEmpty) {
      controller = CameraController(
        CameraService.cameras[0],
        ResolutionPreset.max,
        enableAudio: false,
      );

      controller!.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    HapticService.stopHeartbeat();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Wrap in Semantics so TalkBack knows this is the main interaction area
    return Semantics(
      label: "Camera Viewfinder. Use gestures to interact.",
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,

          // 1. Single Tap: Scene Description [cite: 52]
          onTap: () {
            HapticService.successPulse(); // Instant physical confirmation [cite: 13, 21]
            debugPrint("UI Logic: What is this? (Scene Description)");
            // AUDIO: Trigger "Describing scene..." voice here [cite: 19]
          },

          // 2. Double Tap: OCR/Read Text [cite: 53]
          onDoubleTap: () {
            HapticService.startHeartbeat(); // Loading "heartbeat" pulse [cite: 15]
            debugPrint("UI Logic: Read the text (OCR)");
            // AUDIO: Trigger "Capturing text..." immediately [cite: 20]
          },

          // 3. Long Press: Repeat last instruction [cite: 54]
          onLongPress: () {
            HapticService.successPulse();
            debugPrint("UI Logic: Repeat last thing said");
          },

          // 4. Swipe Vertical: Volume/Speed Control [cite: 55]
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! < 0) {
              debugPrint("UI Logic: Increase Volume/Speed");
            } else if (details.primaryVelocity! > 0) {
              debugPrint("UI Logic: Decrease Volume/Speed");
            }
          },

          child: Stack(
            children: [
              if (controller != null && controller!.value.isInitialized)
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: size.width,
                      height: size.width * controller!.value.aspectRatio,
                      child: CameraPreview(controller!),
                    ),
                  ),
                )
              else
                const Center(child: CircularProgressIndicator(color: Colors.white)),

              const OverlayUI(),
            ],
          ),
        ),
      ),
    );
  }
}