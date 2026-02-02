import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class HapticService {
  static Timer? _heartbeatTimer;

  // Success: Short and clear
// Success: Using a stronger call to ensure it's felt through the phone case
  static void successPulse() {
    HapticFeedback.vibrate(); // This is the strongest standard vibration
    debugPrint("Haptic: Success Pulse Triggered");
  }

  // Error: Three heavy pulses [cite: 14]
  static void errorPattern() async {
    for (int i = 0; i < 3; i++) {
      // Use the full vibrate() for errors to ensure it's felt [cite: 14]
      await SystemChannels.platform.invokeMethod('HapticFeedback.vibrate');
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  // Processing: The continuous heartbeat [cite: 15]
  static void startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      // Light pulse so it doesn't drain battery but stays felt [cite: 15, 16]
      HapticFeedback.mediumImpact();
    });
  }

  static void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}