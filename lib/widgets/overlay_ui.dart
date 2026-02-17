import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OverlayUI extends StatelessWidget {
  const OverlayUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                // .withValues(alpha: 0.7) is the updated way to handle opacity
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
          padding: const EdgeInsets.all(40),
          child: Text(
            "hi guys, camera palang naseset-up ko, di pa pala akeskes mag-include ng color for now",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}