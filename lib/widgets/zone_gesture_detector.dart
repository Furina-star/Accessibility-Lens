import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../services/haptic_service.dart';

class ZoneGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSingleTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onTripleTap;

  // voice command
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final VoidCallback? onLongPressCancel;

  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;


  const ZoneGestureDetector({
    super.key,
    required this.child,
    this.onSingleTap,
    this.onDoubleTap,
    this.onTripleTap,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.onLongPressCancel,
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
  static const Duration doubleTapWindow = Duration(milliseconds: 300);

  Offset? _swipeStart;
  static const double swipeThreshold = 50.0;

  int _activePointers = 0;
  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;
  }

  void _handleTap() {
    if (_activePointers >= 2) return;

    final now = DateTime.now();

    if (_lastTapTime != null && now.difference(_lastTapTime!) < doubleTapWindow) {
      _tapCount++;
    } else {
      _tapCount = 1;
    }

    _lastTapTime = now;

    Future.delayed(doubleTapWindow, () {
      if (_tapCount == 1 && widget.onSingleTap != null) {
        _audio.announceSingleTap();
        widget.onSingleTap!();
      } else if (_tapCount == 2 && widget.onDoubleTap != null) {
        _audio.announceDoubleTap();
        widget.onDoubleTap!();
      } else if (_tapCount >= 3 && widget.onTripleTap != null) {
        _haptics.mediumTap();
        widget.onTripleTap!();
      }
      _tapCount = 0;
    });
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers = 0;
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    _haptics.lightTap();
    widget.onLongPressStart?.call();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    _haptics.lightTap();
    widget.onLongPressEnd?.call();
  }

  void _handleLongPressCancel() {
    _haptics.lightTap();
    widget.onLongPressCancel?.call();
  }

  void _handlePanStart(DragStartDetails details) {
    _swipeStart = details.globalPosition;
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_swipeStart == null) return;

    final delta = details.velocity.pixelsPerSecond;

    if (delta.dy.abs() > delta.dx.abs()) {
      if (delta.dy > swipeThreshold) {
        _handleSwipeDown();
      } else if (delta.dy < -swipeThreshold) {
        _handleSwipeUp();
      }
    } else {
      if (delta.dx > swipeThreshold) {
        _handleSwipeRight();
      } else if (delta.dx < -swipeThreshold) {
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

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: GestureDetector(
        onTap: _handleTap,
        onPanStart: _handlePanStart,
        onPanEnd: _handlePanEnd,
        onLongPressStart: widget.onLongPressStart != null ? _handleLongPressStart : null,
        onLongPressEnd: widget.onLongPressEnd != null ? _handleLongPressEnd : null,
        onLongPressCancel: widget.onLongPressCancel != null ? _handleLongPressCancel : null,
        behavior: HitTestBehavior.opaque,
        child: widget.child,
      ),
    );
  }
}