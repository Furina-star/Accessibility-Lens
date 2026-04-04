# Accessibility Lens

A camera app that narrates the world for visually impaired users. Point it at an object and it speaks out loud (example: “A red coffee mug on a wooden table.”). It can also read text like street signs or medicine labels.

## Features
- Camera-based narration
- Text reading (OCR)
- Audio feedback

## Tech
- Flutter (Dart)
- Android (`android/`)
- iOS (`ios/`)

## Permissions
### Android
Declared in `android/app/src/main/AndroidManifest.xml`:
- Camera
- Microphone
- Internet
- Vibrate

### iOS
Required in `ios/Runner/Info.plist`:
- `NSCameraUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`

## Project Setup

1. **Clone and Get Dependencies**
   ```bash
   git clone https://github.com/Furina-star/Accessibility-Lens.git
   cd Accessibility-Lens
   flutter clean
   flutter pub get
   ```

2. **Environment Variables**
   Create a `.env` file in the root directory and add your API key (e.g., for Gemini):
   ```env
   GEMINI_API_KEY=your_api_key_here
   ```

3. **iOS Setup (Mac Only)**
   Navigate to the iOS folder and install pods:
   ```bash
   cd ios
   pod install
   cd ..
   ```

## Run
*Note: A physical device is highly recommended due to camera and hardware requirements.*
   ```bash
   flutter run
   ```

## Troubleshooting

- **App crashes instantly on launch (iOS):** Ensure `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, and `NSSpeechRecognitionUsageDescription` are set in your `ios/Runner/Info.plist`.
- **GenerativeAIException or API errors:** Ensure your `.env` file exists in the root directory, contains the correct API key, and you have restarted the app completely (not just hot reloaded).
- **Build failed on Android (NDK/CMake):** You may need to install NDK and CMake via Android Studio SDK Manager, or enable `multiDexEnabled true` in `android/app/build.gradle`.
- **Pod install fails on Apple Silicon:** Run `arch -x86_64 pod install --repo-update` inside the `ios` directory.
- **Speech-to-text not working:** Ensure the device has an active internet connection and that the Google app (Android) or Siri (iOS) is enabled and up-to-date.

## Notes
- iOS launch images: `ios/Runner/Assets.xcassets/LaunchImage.imageset/`