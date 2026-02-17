import 'package:flutter/material.dart';

/// Semantic wrapper widgets for proper screen reader support
/// Every interactive element MUST be wrapped in proper semantics

class SemanticButton extends StatelessWidget {
  final String label;
  final String? hint;
  final VoidCallback onPressed;
  final Widget child;

  const SemanticButton({
    super.key,
    required this.label,
    this.hint,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: true,
      onTap: onPressed,
      child: GestureDetector(
        onTap: onPressed,
        child: child,
      ),
    );
  }
}

class SemanticCameraView extends StatelessWidget {
  final Widget child;
  final String statusMessage;

  const SemanticCameraView({
    super.key,
    required this.child,
    this.statusMessage = "Camera view active",
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Camera viewfinder",
      hint: statusMessage,
      image: true,
      child: ExcludeSemantics(
        // Exclude the raw camera preview from semantics
        excluding: true,
        child: child,
      ),
    );
  }
}

class SemanticText extends StatelessWidget {
  final String text;
  final Widget child;
  final bool isLiveRegion;

  const SemanticText({
    super.key,
    required this.text,
    required this.child,
    this.isLiveRegion = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      liveRegion: isLiveRegion,
      child: child,
    );
  }
}

class SemanticGestureZone extends StatelessWidget {
  final String label;
  final String hint;
  final Widget child;

  const SemanticGestureZone({
    super.key,
    required this.label,
    required this.hint,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      container: true,
      child: child,
    );
  }
}

/// Announces changes to screen reader without visual change
class LiveRegionAnnouncer extends StatelessWidget {
  final String message;
  final Widget? child;

  const LiveRegionAnnouncer({
    super.key,
    required this.message,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message,
      liveRegion: true,
      child: child ?? const SizedBox.shrink(),
    );
  }
}