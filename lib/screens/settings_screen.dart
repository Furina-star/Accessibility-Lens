import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../services/haptic_service.dart';
import '../services/camera_guidance_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AudioFeedbackManager _audio = AudioFeedbackManager();
  final HapticService _haptics = HapticService();
  final CameraGuidanceService _guidance = CameraGuidanceService();

  bool _ttsEnabled = true;
  bool _hapticsEnabled = true;
  bool _guidanceEnabled = true;

  double _speechRate = 0.5;
  double _pitch = 1.0;

  // voice picker
  String _voiceLabel = "Default";

  static const Color bg = Colors.black;
  static const Color accent = Color(0xFFFFC107);
  static const Color textDim = Color(0xFFFFE082);

  @override
  void initState() {
    super.initState();
    _ttsEnabled = _audio.ttsEnabled;
    _guidanceEnabled = _guidance.isMonitoring;
  }

  Future<void> _setTtsEnabled(bool v) async {
    setState(() => _ttsEnabled = v);
    if (v) {
      await _audio.enableTts();
      await _audio.speak("Speech on");
    } else {
      await _audio.disableTts();
    }
  }

  void _setHapticsEnabled(bool v) async {
    setState(() => _hapticsEnabled = v);
    if (!v) {
      _haptics.stop();
    } else {
      _haptics.lightTap();
    }
  }

  void _setGuidanceEnabled(bool v) async {
    setState(() => _guidanceEnabled = v);


    if (!v) {
      _guidance.stopMonitoring();
      await _audio.speak("Camera guidance off");
    } else {
      await _audio.speak("Camera guidance on");
    }
  }

  Future<void> _setSpeechRate(double v) async {
    setState(() => _speechRate = v);
    await _audio.setSpeechRate(v);
    await _audio.speak("Speech rate ${(_speechRate * 10).round()}");
  }

  Future<void> _setPitch(double v) async {
    setState(() => _pitch = v);


    await _audio.speak("Pitch updated");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: accent,
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Speech", context),
          _switchTile(
            title: "Text to speech",
            subtitle: "Turn spoken feedback on or off",
            value: _ttsEnabled,
            onChanged: (v) => _setTtsEnabled(v),
          ),
          _tile(
            title: "Voice",
            subtitle: _voiceLabel,
            trailing: const Icon(Icons.chevron_right, color: accent),
            onTap: () async {
              // Placeholder until you expose actual installed voices
              setState(() => _voiceLabel = _voiceLabel == "Default" ? "Alt voice" : "Default");
              await _audio.speak("Voice changed");
            },
          ),
          _sliderTile(
            title: "Speech rate",
            subtitle: "Adjust speaking speed",
            value: _speechRate,
            min: 0.1,
            max: 0.9,
            onChanged: (v) => _setSpeechRate(v),
          ),
          _sliderTile(
            title: "Pitch",
            subtitle: "Adjust voice pitch",
            value: _pitch,
            min: 0.7,
            max: 1.3,
            onChanged: (v) => _setPitch(v),
          ),

          const SizedBox(height: 20),
          _sectionTitle("Feedback", context),
          _switchTile(
            title: "Haptics",
            subtitle: "Vibration feedback",
            value: _hapticsEnabled,
            onChanged: (v) => _setHapticsEnabled(v),
          ),
          _switchTile(
            title: "Camera guidance",
            subtitle: "Lens blocked / too dark alerts",
            value: _guidanceEnabled,
            onChanged: (v) => _setGuidanceEnabled(v),
          ),

          const SizedBox(height: 20),
          _sectionTitle("About", context),
          _tile(
            title: "Gesture help",
            subtitle: "Hear the controls again",
            trailing: const Icon(Icons.play_arrow, color: accent),
            onTap: () async {
              await _audio.speak(
                "Single tap to describe scene. Double tap to read text. Long press to repeat. Swipe up or down changes speed. Swipe left turns speech off. Swipe right turns speech on.",
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: accent,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _tile({
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      title: Text(title, style: const TextStyle(color: accent, fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle, style: const TextStyle(color: textDim)),
      trailing: trailing,
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(color: accent, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: textDim)),
      activeColor: accent,
      inactiveThumbColor: Colors.grey,
      inactiveTrackColor: Colors.grey.shade800,
    );
  }

  Widget _sliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(title, style: const TextStyle(color: accent, fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: const TextStyle(color: textDim)),
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accent,
            inactiveTrackColor: Colors.grey.shade800,
            thumbColor: accent,
            overlayColor: accent.withValues(alpha: 0.2),
            valueIndicatorColor: accent,
            valueIndicatorTextStyle: const TextStyle(color: Colors.black),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: 8,
            label: value.toStringAsFixed(2),
            onChanged: (v) => onChanged(v),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}