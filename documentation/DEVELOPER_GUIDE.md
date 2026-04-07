# Developer Guide — Accessibility Lens

**Last updated:** 2026-04-07

## Clone the repository through git (bash)
- **git clone https://github.com/Furina-star/Accessibility-Lens.git**
- cd Accessibility-Lens
- flutter clean
- flutter pub get

## Environment Variables (.env file)
- Create an .env file in the root directory
- Add the API key for gemini
- GEMINI_API_KEY=your_api_key_here

## Android Setup
Google ML Kit and Camera Dependencies requires a higher minimum SDK version
- Open android/app/build.gradle
- Ensure minSdkVersion is set to at least 21
- Ensure compileSdkVersion is set to at least 34


## Troubleshoot
**Issue 1: App crashes instantly on launch (iOS)**
- Cause: Missing permission descriptions in Info.plist. The permission_handler and camera packages will fatally crash the app if the usage descriptions aren't provided.
- Fix: Open XCode or edit ios/Runner/Info.plist directly and add string values for Camera, Microphone, and Speech Recognition.

**Issue 2: "GenerativeAIException" or API errors**
- Cause: Missing or invalid .env file.
- Fix: Ensure your .env file is located exactly in the root folder, that it is listed under assets: in pubspec.yaml (which it currently is), and that you have a valid Gemini API key. Make sure to restart the app completely after adding the .env file (hot reload won't load new assets).

**Issue 3: Build failed on Android (NDK or CMake errors)**
- Cause: Google ML Kit packages (google_mlkit_text_recognition, etc.) use pre-compiled C++ binaries. Sometimes Gradle fails to link them if the NDK version is mismatched or if the app exceeds the 64K method limit.
- Fix: Open android/app/build.gradle and enable MultiDex if needed: multiDexEnabled true. If it complains about CMake/NDK, open Android Studio -> SDK Manager -> SDK Tools -> Check "NDK (Side by side)" and "CMake" and install them.

**Issue 4: Pod install fails on Apple Silicon (M1/M2/M3)**
- Cause: The Ruby FFI library or ML Kit pods sometimes struggle with ARM64 architecture during pod install.
- Fix: Run this command in your ios folder:
arch -x86_64 pod install --repo-update

**Also, ensure the iOS deployment target in ios/Podfile is set to at least platform :ios, '12.0' or higher, as ML Kit requires it.**

### Issue 5: speech_to_text is not working / always returning errors
- Cause: The speech recognition engine varies heavily by device. On Android, it relies on the Google App being installed and updated. On iOS, it relies on Siri.
- Fix: Ensure the physical test device has an active internet connection (speech recognition often requires it unless offline models are downloaded via the OS settings) and that the Google app is up-to-date on Android test devices.
