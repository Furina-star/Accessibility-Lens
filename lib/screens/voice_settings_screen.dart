import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({
    super.key,
    this.initialSelectionLabel,
  });

  final String? initialSelectionLabel;

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  final AudioFeedbackManager _audio = AudioFeedbackManager();

  bool _loading = true;
  List<Map<String, String>> _voices = const [];
  String _query = "";

  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    try {
      final voices = await _audio.getAvailableVoices();
      if (!mounted) return;
      setState(() {
        _voices = voices;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      await _audio.speak("Failed to load voices");
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _voices.where((v) {
      final name = (v['name'] ?? '').toLowerCase();
      final locale = (v['locale'] ?? '').toLowerCase();
      final q = _query.toLowerCase().trim();
      if (q.isEmpty) return true;
      return name.contains(q) || locale.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFFFC107),
        title: const Text("Voice"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search voice or locale (e.g. en-US)",
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFFC107)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFFFC107)),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
              child: Text(
                "No voices found",
                style: TextStyle(color: Colors.white70),
              ),
            )
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final v = filtered[i];
                final name = v['name'] ?? '';
                final locale = v['locale'] ?? '';
                final label = "$locale — $name";

                return ListTile(
                  title: Text(
                    label,
                    style: const TextStyle(color: Color(0xFFFFC107)),
                  ),
                  subtitle: const Text(
                    "Tap to select",
                    style: TextStyle(color: Color(0xFFFFE082)),
                  ),
                  onTap: () async {
                    // Apply voice immediately
                    await _audio.setVoiceByNameAndLocale(
                      name: name,
                      locale: locale,
                    );

                    // Return selection back to settings
                    if (!context.mounted) return;
                    Navigator.pop(context, v);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}