# Privacy Policy — Accessibility Lens

**Last updated:** 2026-04-04

This Privacy Policy explains how Accessibility Lens uses camera, microphone, and network services to provide accessibility features.

## Summary (plain language)
- The app uses your **camera** to capture images for scene description and text reading.
- The app uses your **microphone** only when you press and hold to speak a voice command.
- The app may send **captured images** and/or **recognized text** to an external AI service (Gemini) to generate spoken descriptions.
- The app attempts to **delete captured images after processing**.

## Camera and images
The app uses the camera for:
- Live camera preview
- Camera guidance monitoring (detecting very dark/low light conditions)
- Capturing a still image when you trigger:
    - Scene description (single tap)
    - Text reading (double tap)

### Temporary image files
When a capture occurs, the app takes a photo, processes it, and then deletes the photo file (best effort). In rare cases (for example, if the app crashes), deletion may not occur.

## Microphone and voice commands
The app listens to the microphone **only while the user is actively holding to talk** to issue a command. It stops listening when the user releases.

## AI processing and network use (Gemini)
Accessibility Lens uses Gemini (via the `google_generative_ai` library) to:
- Clean and format OCR text so it can be read clearly via text-to-speech
- Generate short scene descriptions from captured images
This means that content from the camera (images) and/or extracted text may be transmitted over the network to the AI service to generate results.

## Data storage
Accessibility Lens is designed to function without creating user accounts.
- The app does not intentionally store a history of images or transcripts inside the app.
- The app keeps the “last spoken message” in memory so the user can use “Repeat”.

## Permissions
The app may request:
- Camera permission (required for core features)
- Microphone permission (required for voice commands)


## Contact
- Email: mlb.bello@unp.edu.ph / mja.magos@unp.edu.ph / jb.cadizal@unp.edu.ph
- Developers: Michael Lorenz B. Bello / Mary Jobelle A. Magos / Jomel B. Cadizal