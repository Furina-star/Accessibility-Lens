import 'package:flutter/material.dart';

class VisualOverlay extends StatelessWidget {
  final String? topMessage;
  final String? centerMessage;
  final String? bottomMessage;
  final String? alertMessage;
  final double? progressValue;
  final bool showSettings;
  final VoidCallback? onSettingsTap;

  const VisualOverlay({
    super.key,
    this.topMessage,
    this.centerMessage,
    this.bottomMessage,
    this.alertMessage,
    this.progressValue,
    this.showSettings = true,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Stack(
        children: [
          if (topMessage != null || showSettings) _buildTopBar(),
          if (alertMessage != null) _buildAlertMessage(),
          if (progressValue != null) _buildProgressIndicator(),
          if (bottomMessage != null) _buildBottomMessage(),
          if (centerMessage != null) _buildCenterMessage(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 15),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              topMessage ?? 'ACCESSIBILITY LENS',
              style: const TextStyle(
                color: Color(0xFFFFC107),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            if (showSettings)
              GestureDetector(
                onTap: onSettingsTap,
                child: const Icon(
                  Icons.settings,
                  color: Color(0xFFFFC107),
                  size: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertMessage() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 30),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFFFC107),
              width: 3,
            ),
          ),
          child: Text(
            alertMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFFC107),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Positioned(
      top: 120,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: progressValue,
                strokeWidth: 4,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
                backgroundColor: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progressValue! * 100).toInt()}%',
              style: const TextStyle(
                color: Color(0xFFFFC107),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomMessage() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFFFFC107).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Text(
          bottomMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFFFC107),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCenterMessage() {
    return Positioned(
      bottom: 150,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFFFC107),
            width: 2,
          ),
        ),
        child: Text(
          centerMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFFFC107),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}