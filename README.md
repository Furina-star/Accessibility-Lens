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

## Permissions (Android)
Declared in `android/app/src/main/AndroidManifest.xml`:
- Camera
- Microphone
- Internet
- Vibrate

## Run
```bash
flutter pub get
flutter run
```

## Notes
- iOS launch images: `ios/Runner/Assets.xcassets/LaunchImage.imageset/`
