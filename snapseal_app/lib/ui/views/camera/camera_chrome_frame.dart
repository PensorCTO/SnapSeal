import 'package:flutter/material.dart';

/// Thin metallic-looking bezel around the camera preview (no blur over the feed).
class CameraChromeFrame extends StatelessWidget {
  const CameraChromeFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A4A4A),
            Color(0xFFB8B8B8),
            Color(0xFF6E6E6E),
            Color(0xFF9A9A9A),
          ],
          stops: [0.0, 0.38, 0.62, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3.5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: ColoredBox(
          color: Colors.black,
          child: child,
        ),
      ),
    );
  }
}
