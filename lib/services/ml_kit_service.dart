import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_genai_image_description/google_mlkit_genai_image_description.dart';
import 'package:google_mlkit_genai_prompt/google_mlkit_genai_prompt.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import '../services/tts_service.dart'; // Changed from audio_feedback_manager
import '../services/haptic_service.dart';

// IDK hahaahah

// Object Detection Dummy Test to detect one or more multiple objects via live Camera
/*
class ObjectDetectionService {
  late ObjectDetector _objectDetector;

  ObjectDetectionService() {
    // Configure the detector
    final options = ObjectDetectorOptions(
      mode: DetectionMode.single, // Use .stream for live camera
      classifyObjects: true,      // Identify what the object is
      multipleObjects: true,      // Detect more than one item
    );
    _objectDetector = ObjectDetector(options: options);
  }

  /// The function to call out
  Future<List<DetectedObject>> detectInImage(String filePath) async {
    final inputImage = InputImage.fromFilePath(filePath);

    // Process the image
    final List<DetectedObject> objects = await _objectDetector.processImage(inputImage);

    return objects;
  }

  void dispose() {
    _objectDetector.close();
  }
}
*/

// Genai Image Description and Prompt are Complicated
