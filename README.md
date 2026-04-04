# Accessibility Lens

Accessibility Lens is a Flutter mobile app designed to assist visually impaired users by using the camera, speech output (TTS), haptics, and voice commands to describe scenes and read text.

## Key features
- Scene description (single tap)
- Text reading (double tap)
- Voice commands (long press / hold to talk)
- Camera guidance alerts (lens blocked / too dark) using haptics + announcements
- Adjustable speech rate and pitch
- Voice selection (voice + locale picker)

## Quick start (developer)
1. Install Flutter and set up Android Studio/Xcode.
2. Create a `.env` file at the project root with:

   `GEMINI_API_KEY=your_key_here`

3. Ensure `.env` is included as an asset in `pubspec.yaml` (see Developer Guide).
4. Run:
   ```bash
   flutter pub get
   flutter run
   ```

## Documentation
- How to use the app: `docs/USER_GUIDE.md`
- Developer setup: `docs/DEVELOPER_GUIDE.md`
- Privacy policy: `docs/PRIVACY_POLICY.md`