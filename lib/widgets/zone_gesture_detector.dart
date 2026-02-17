import 'package:flutter/material.dart';
import '../services/tts_service.dart'; // Changed from audio_feedback_manager
import '../services/haptic_service.dart';

/// Zone-Based Gesture System
/// Replaces buttons with intuitive, location-independent gestures
class ZoneGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSingleTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const ZoneGestureDetector({
    super.key,
    required this.child,
    this.onSingleTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<ZoneGestureDetector> createState() => _ZoneGestureDetectorState();
}

class _ZoneGestureDetectorState extends State<ZoneGestureDetector> {
  final AudioFeedbackManager _audio = AudioFeedbackManager();
  final HapticService _haptics = HapticService();

  int _tapCount = 0;
  DateTime? _lastTapTime;
  static const Duration DOUBLE_TAP_WINDOW = Duration(milliseconds: 300);

  Offset? _swipeStart;
  static const double SWIPE_THRESHOLD = 50.0;

  // ==================== TAP HANDLING ====================

  void _handleTap() {
    final now = DateTime.now();

    if (_lastTapTime != null && now.difference(_lastTapTime!) < DOUBLE_TAP_WINDOW) {
      _tapCount++;
    } else {
      _tapCount = 1;
    }

    _lastTapTime = now;

    if (_tapCount == 1) {
      // Wait to see if it's a double tap
      Future.delayed(DOUBLE_TAP_WINDOW, () {
        if (_tapCount == 1 && widget.onSingleTap != null) {
          _audio.announceSingleTap();
          widget.onSingleTap!();
        }
        _tapCount = 0;
      });
    } else if (_tapCount == 2 && widget.onDoubleTap != null) {
      _audio.announceDoubleTap();
      widget.onDoubleTap!();
      _tapCount = 0;
    }
  }

  void _handleLongPress() {
    if (widget.onLongPress != null) {
      _audio.announceLongPress();
      widget.onLongPress!();
    }
  }

  // ==================== SWIPE HANDLING ====================

  void _handlePanStart(DragStartDetails details) {
    _swipeStart = details.globalPosition;
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_swipeStart == null) return;

    final delta = details.velocity.pixelsPerSecond;

    // Determine swipe direction based on velocity
    if (delta.dy.abs() > delta.dx.abs()) {
      // Vertical swipe
      if (delta.dy > SWIPE_THRESHOLD) {
        _handleSwipeDown();
      } else if (delta.dy < -SWIPE_THRESHOLD) {
        _handleSwipeUp();
      }
    } else {
      // Horizontal swipe
      if (delta.dx > SWIPE_THRESHOLD) {
        _handleSwipeRight();
      } else if (delta.dx < -SWIPE_THRESHOLD) {
        _handleSwipeLeft();
      }
    }

    _swipeStart = null;
  }

  void _handleSwipeUp() {
    if (widget.onSwipeUp != null) {
      _haptics.lightTap();
      widget.onSwipeUp!();
    }
  }

  void _handleSwipeDown() {
    if (widget.onSwipeDown != null) {
      _haptics.lightTap();
      widget.onSwipeDown!();
    }
  }

  void _handleSwipeLeft() {
    if (widget.onSwipeLeft != null) {
      _haptics.lightTap();
      widget.onSwipeLeft!();
    }
  }

  void _handleSwipeRight() {
    if (widget.onSwipeRight != null) {
      _haptics.lightTap();
      widget.onSwipeRight!();
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onLongPress: _handleLongPress,
      onPanStart: _handlePanStart,
      onPanEnd: _handlePanEnd,
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}