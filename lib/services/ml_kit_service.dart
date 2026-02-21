import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_genai_prompt/google_mlkit_genai_prompt.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'dart:io';

// IDK hahaahah
class TextRecognitionService {
  late TextRecognizer _textRecognizer;

  TextRecognitionService() {
    // Initialize with default Latin script
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  /// Processes the image and returns the recognized text string
  Future<String> processImage(String path) async {
    final inputImage = InputImage.fromFilePath(path);

    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text.trim();
    } catch (e) {
      print("OCR Service Error: $e");
      return "";
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}

// Object Detection Dummy Test to detect one or more multiple objects via live Camera
class SceneDescriptionService {
  final String _apiKey = "AIzaSyAuBk1Hu76CtsE0k_on7q6RwIEwChjkWfU";
  late GenerativeModel _model;

  SceneDescriptionService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: _apiKey,
    );
  }

  Future<String> describeScene(String path) async {
    try {
      final file = File(path);
      final imageBytes = await file.readAsBytes();

      final prompt = TextPart(
          "Describe this image briefly for someone who is blind. "
              "Focus on the most important objects and their relative positions. "
              "Keep it under 3 sentences."
      );

      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      return response.text ?? "I see a scene but cannot describe it.";
    } catch (e) {
      print("FULL GEMINI ERROR: $e"); // Check your Debug Console for this!
      return "Connection error: $e";
    }
  }
}

// Genai Image Description and Prompt are Complicated
