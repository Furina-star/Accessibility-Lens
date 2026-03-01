import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

/// GEMINI AI Model
GenerativeModel _createGeminiModel(String systemInstruction) {
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.trim().isEmpty) {
    throw Exception('API Key not found in .env file!');
  }

  return GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
    systemInstruction: Content.system(systemInstruction),
    safetySettings: [
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
    ],
  );
}

/// OCR Detection
class TextRecognitionService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  late final GenerativeModel _geminiModel;

  TextRecognitionService() {
    _geminiModel = _createGeminiModel("""
      You are a helpful assistant reading text aloud for a visually impaired user. 
      Process all text for a Text-to-Speech audio engine using these strict rules:
      1. Context First: Start with a single, short sentence explaining what you are looking at.
      2. Clean and Logical: Read the main content clearly. Fix obvious OCR typos silently. Read tables left-to-right, top-to-bottom.
      3. No Formatting Symbols: DO NOT use Markdown formatting. No asterisks, hashtags, underscores, or bullets. Use commas and periods only.
      4. Skip the Garbage: Ignore random gibberish characters or meaningless numbers.
      5. Be Concise: Do not add conversational filler. Just start reading.
    """);
  }

  Future<String> processImage(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    final String rawText = recognizedText.text.trim();

    if (rawText.isEmpty) return "";

    // The API request
    final response = await _geminiModel.generateContent([
      Content.text("Here is the raw text to read:\n$rawText")
    ]);

    return response.text?.trim() ?? "";
  }

  void dispose() {
    _textRecognizer.close();
  }
}

/// Scene Detection
class SceneDescriptionService {
  late final GenerativeModel _geminiModel;
  late final ObjectDetector _objectDetector;

  SceneDescriptionService() {
    _geminiModel = _createGeminiModel("""
      You are a helpful assistant acting as the eyes for a visually impaired user. 
      Analyze images and describe the scene specifically for a Text-to-Speech audio engine.
      Follow these strict rules:
      1. The Big Picture: Start with a single sentence summarizing the environment.
      2. Spatial Layout: Describe main objects and where they are relative to the user (e.g., "directly in front of you").
      3. Hazard Warning: Explicitly call out potential obstacles, tripping hazards, or drop-offs.
      4. Audio-Friendly: DO NOT use Markdown formatting, lists, or bullets. Use only commas and periods.
      5. Keep it Concise: Keep the entire description under 4 sentences.
    """);

    final options = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<String> describeScene(String path) async {
    final file = File(path);
    final imageBytes = await file.readAsBytes();
    final inputImage = InputImage.fromFilePath(path);

    String mlKitHints = "";
    try {
      final List<DetectedObject> objects = await _objectDetector.processImage(inputImage);

      List<String> labels = [];
      for (final object in objects) {
        for (final label in object.labels) {
          labels.add(label.text);
        }
      }

      // If ML Kit finds things, format them into a hint string for Gemini
      if (labels.isNotEmpty) {
        // Remove duplicate labels (e.g., if it sees three "chairs", just say "chair" once for the hint)
        final uniqueLabels = labels.toSet().toList();
        mlKitHints = "There is the presence of: ${uniqueLabels.join(', ')}. ";
      }
    } catch (e) {
      print("ML Kit Object Detection skipped/failed: $e");
    }

    final promptText = mlKitHints.isEmpty
        ? "Describe this scene for me."
        : "$mlKitHints Please describe the scene, paying special attention to where these objects are located relative to the camera, especially if they are hazards.";

    try {
      final response = await _geminiModel.generateContent([
        Content.multi([
          TextPart(promptText),
          DataPart('image/jpeg', imageBytes)
        ])
      ]);

      return response.text?.trim() ?? "I see a scene but cannot describe it right now.";
    } catch (e) {
      print("Gemini Scene Error: $e");
      return "There was an issue processing the scene description.";
    }
  }

  void dispose() {
    _objectDetector.close();
  }
}

/*
/// --- Barcode Detection ---
class BarcodeService {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  Future<String> scanImage(String path) async {
    final inputImage = InputImage.fromFilePath(path);

    try {
      final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);
      if (barcodes.isEmpty) return "";

      final String rawValue = barcodes.first.rawValue ?? "";
      return rawValue.isEmpty ? "" : rawValue;
    } catch (e) {
      print("Static Barcode Scanner Error: $e");
      return "";
    }
  }

  Future<String> processLiveFrame(InputImage inputImage) async {
    try {
      final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);
      if (barcodes.isEmpty) return "";

      final String rawValue = barcodes.first.rawValue ?? "";
      return rawValue;
    } catch (e) {
      print("Live Barcode Scanner Error: $e");
      return "";
    }
  }

  void dispose() {
    _barcodeScanner.close();
  }
}

InputImage? convertCameraImageToInputImage(CameraImage image, CameraController controller) {
  final sensorOrientation = controller.description.sensorOrientation;
  InputImageRotation? rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
  if (rotation == null) return null;

  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  if (format == null ||
      (Platform.isAndroid && format != InputImageFormat.nv21) ||
      (Platform.isIOS && format != InputImageFormat.bgra8888)) {
    return null;
  }

  if (image.planes.isEmpty) return null;
  final WriteBuffer allBytes = WriteBuffer();
  for (final Plane plane in image.planes) {
    allBytes.putUint8List(plane.bytes);
  }
  final bytes = allBytes.done().buffer.asUint8List();

  final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
  final inputImageMetadata = InputImageMetadata(
    size: imageSize,
    rotation: rotation,
    format: format,
    bytesPerRow: image.planes[0].bytesPerRow,
  );

  return InputImage.fromBytes(
    bytes: bytes,
    metadata: inputImageMetadata,
  );
}
*/
