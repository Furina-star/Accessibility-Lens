import 'package:speech_to_text/speech_to_text.dart' as stt;

enum VoiceCommand {
  captureScene, // Capture the current scene and provide a description
  captureText, // Capture text from the scene and read it aloud
  volumeUp, // Increase the volume of the speech output
  volumeDown, // Decrease the volume of the speech output
  stop, // Stop the prompted message
  forceStop, // Force stop the app itself
  exit, // Exit the app
  speedUp, // Speed up the speech rate
  slowDown, // Slow down the speech rate  
  repeat, // Repeat the last prompted message
  help, // Provide a list of available voice commands
  unknown,
}

// A simple parser to convert raw voice input into structured commands
class VoiceCommandParser {
  static VoiceCommand parse(String raw) {
    final text = raw.toLowerCase().trim();

    // Capture Scene
    if (text.contains("capture scene") ||
        text.contains("describe scene") ||
        text.contains("what's around me") ||
        text.contains("what is this") ||
        text == "scene") {
      return VoiceCommand.captureScene;
    }

    // Capture Text
    if (text.contains("capture text") ||
        text.contains("read text") ||
        text.contains("what does this say") ||
        text.contains("what's written") ||
        text == "text") {
      return VoiceCommand.captureText;
    }

    // Volume Control
    if (text.contains("volume up") ||
        text.contains("increase volume") ||
        text == "louder") {
      return VoiceCommand.volumeUp;
    }
    if (text.contains("volume down") ||
        text.contains("decrease volume") ||
        text == "quieter") {
      return VoiceCommand.volumeDown;
    }

    // Stop Speaking
    if (text == "stop" ||
        text.contains("stop speaking") ||
        text.contains("stop talking") ||
        text.contains("stop voice")) {
      return VoiceCommand.stop;
    }

    // Force Stop App
    if (text.contains("force stop") ||
        text.contains("force close") ||
        text.contains("reset app") ||
        text.contains("restart app")) {
      return VoiceCommand.forceStop;
    }

    // Exit App
    if (text == "exit" ||
        text.contains("close app") ||
        text.contains("exit app") ||
        text.contains("quit") ||
        text == "close") {
      return VoiceCommand.exit;
    }

    // Adjust Speech Rate
    if (text.contains("speed up") || text.contains("faster")) return VoiceCommand.speedUp;
    if (text.contains("slow down") || text.contains("slower")) return VoiceCommand.slowDown;

    // Repeat Last Message
    if (text.contains("repeat") ||
        text.contains("say that again") ||
        text.contains("what did you say") ||
        text.contains("can you repeat that")) {
      return VoiceCommand.repeat;
    }

    // Help Command
    if (text.contains("help") ||
        text.contains("what can i say") ||
        text.contains("list commands") ||
        text.contains("available commands")) {
      return VoiceCommand.help;
    }

    return VoiceCommand.unknown;
  }
}

// The main service that listens for voice commands and executes corresponding actions
class VoiceCommandService {
  final stt.SpeechToText _stt = stt.SpeechToText();

  bool _available = false;
  bool _isListening = false;

  bool get isListening => _isListening;

  Future<bool> init() async {
    _available = await _stt.initialize(
      onError: (e) => print("Speech recognition error: $e"),
      onStatus: (s) => print("Speech recognition status: $s"),
    );
    return _available;
  }

  Future<void> startHoldToTalk({
    required void Function(String words, bool isFinal) onWords,
  }) async {
    if (!_available) return;
    if (_isListening) return;

    await _stt.listen(
      partialResults: true,
      listenMode: stt.ListenMode.confirmation,
      onResult: (result) {
        onWords(result.recognizedWords, result.finalResult);
      },
    );
  }

  Future<void> stopHoldToTalk() async {
    _isListening = false;
    await _stt.stop();
  }

  Future<void> cancel() async {
    _isListening = false;
    await _stt.cancel();
  }

  void dispose() {
    _stt.cancel();
  }
}
