import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

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
  final TextRecognizer _textRecognizer =
  TextRecognizer(script: TextRecognitionScript.latin);
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
      6. Read this menu/receipt item by item. For each item, state the name followed immediately by its price. Do not list all names then all prices.
    """);
  }

  Future<String> processImage(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final RecognizedText recognizedText =
    await _textRecognizer.processImage(inputImage);
    final String rawText = recognizedText.text.trim();

    // FIX: If text is basically non-existent (less than 3 characters), 
    // return empty so we don't call Gemini.
    if (rawText.length < 3) return "";

    // The API request
    final response = await _geminiModel.generateContent(
      [Content.text("Here is the raw text to read:\n$rawText")],
    );

    return response.text?.trim() ?? "";
  }

  void dispose() {
    _textRecognizer.close();
  }
}

/// Scene Detection
class SceneDescriptionService {
  late final GenerativeModel _geminiModel;

  SceneDescriptionService() {
    _geminiModel = _createGeminiModel("""
      You are a helpful assistant acting as the eyes for a visually impaired user. 
      Analyze images and describe the scene specifically for a Text-to-Speech audio engine.
      "PRIORITY 1: Identify immediate tripping hazards or head-level obstacles (open cabinets, shoes, stairs). "
      "PRIORITY 2: Describe the overall room and exits. "
      "If the image is too blurry, too dark, or a close-up with no context, BE HONEST. "
      "Say 'I am too close to an object to see it' or 'It is too dark' instead of guessing. "
      Follow these strict rules:
      1. The Big Picture: Start with a single sentence summarizing the environment.
      2. Spatial Layout: Describe main objects and where they are relative to the user (e.g., "directly in front of you").
      3. Hazard Warning: Explicitly call out potential obstacles, tripping hazards, or drop-offs.
      4. Audio-Friendly: DO NOT use Markdown formatting, lists, or bullets. Use only commas and periods.
      5. Keep it Concise: Keep the entire description under 4 sentences.
    """);
  }

  Future<String> describeScene(String path) async {
    final file = File(path);
    final imageBytes = await file.readAsBytes();

    final response = await _geminiModel.generateContent([
      Content.multi([
        TextPart("Describe this scene for me."),
        DataPart('image/jpeg', imageBytes),
      ])
    ]);

    return response.text?.trim() ?? "I see a scene but cannot describe it right now.";
  }
}