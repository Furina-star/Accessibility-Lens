import 'package:flutter/material.dart';

/// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Accessibility Lens';
  static const String appVersion = '1.0.0';

  // Speech Settings
  static const double defaultSpeechRate = 0.5;
  static const double minSpeechRate = 0.1;
  static const double maxSpeechRate = 0.9;
  static const double speechRateStep = 0.1;

  // Volume Settings
  static const double defaultVolume = 1.0;
  static const double volumeStep = 0.1;

  // ML Kit Settings
  static const double confidenceThreshold = 0.5;

  // Haptic Durations (milliseconds)
  static const int hapticLight = 30;
  static const int hapticMedium = 50;
  static const int hapticHeavy = 100;
}

/// App Colors
class AppColors {
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color accent = Color(0xFF00E676);
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color error = Color(0xFFCF6679);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFFFFFFF);
}

/// Scan Modes
enum ScanMode {
  auto,
  text,
  object,
  barcode,
}

extension ScanModeExtension on ScanMode {
  String get displayName {
    switch (this) {
      case ScanMode.auto:
        return 'Auto';
      case ScanMode.text:
        return 'Text';
      case ScanMode.object:
        return 'Objects';
      case ScanMode.barcode:
        return 'Barcode';
    }
  }

  String get description {
    switch (this) {
      case ScanMode.auto:
        return 'Automatically detect text and objects';
      case ScanMode.text:
        return 'Read text from images';
      case ScanMode.object:
        return 'Identify objects';
      case ScanMode.barcode:
        return 'Scan barcodes and QR codes';
    }
  }
}