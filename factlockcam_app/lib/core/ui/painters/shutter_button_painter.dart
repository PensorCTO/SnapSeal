import 'package:flutter/material.dart';

/// Paints a camera shutter button with a transparent center by default.
class ShutterButtonPainter extends CustomPainter {
  const ShutterButtonPainter({
    this.fillColor,
    this.fillProgress = 0,
    this.outerStrokeWidth = 2.0,
    this.innerInset = 8.0,
  });

  final Color? fillColor;
  final double fillProgress;
  final double outerStrokeWidth;
  final double innerInset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = (size.shortestSide - outerStrokeWidth) / 2;
    final innerRadius = (outerRadius - innerInset).clamp(0.0, outerRadius);

    final clampedProgress = fillProgress.clamp(0.0, 1.0);
    final color = fillColor;
    if (color != null && clampedProgress > 0) {
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, innerRadius * clampedProgress, fillPaint);
    }

    final ringPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = outerStrokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, outerRadius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant ShutterButtonPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.fillProgress != fillProgress ||
        oldDelegate.outerStrokeWidth != outerStrokeWidth ||
        oldDelegate.innerInset != innerInset;
  }
}
