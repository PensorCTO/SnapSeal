import 'package:flutter/material.dart';

/// Optical corner reticle, center crosshair, and cinematic aspect-ratio guides.
///
/// [guideAspectRatio] is width/height (e.g. `16 / 9` or `2.35`).
/// Repaints only when [guideAspectRatio] changes.
class ReticlePainter extends CustomPainter {
  const ReticlePainter({required this.guideAspectRatio});

  final double guideAspectRatio;

  static const double _inset = 16;
  static const double _arm = 24;
  static const double _cornerStroke = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = _cornerStroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    // Top-left
    canvas.drawLine(const Offset(_inset, _inset), Offset(_inset + _arm, _inset), cornerPaint);
    canvas.drawLine(const Offset(_inset, _inset), Offset(_inset, _inset + _arm), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(w - _inset, _inset), Offset(w - _inset - _arm, _inset), cornerPaint);
    canvas.drawLine(Offset(w - _inset, _inset), Offset(w - _inset, _inset + _arm), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(_inset, h - _inset), Offset(_inset + _arm, h - _inset), cornerPaint);
    canvas.drawLine(Offset(_inset, h - _inset), Offset(_inset, h - _inset - _arm), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(w - _inset, h - _inset), Offset(w - _inset - _arm, h - _inset), cornerPaint);
    canvas.drawLine(Offset(w - _inset, h - _inset), Offset(w - _inset, h - _inset - _arm), cornerPaint);

    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const crossHalf = 18.0;
    final cx = w / 2;
    final cy = h / 2;
    canvas.drawLine(Offset(cx - crossHalf, cy), Offset(cx + crossHalf, cy), crossPaint);
    canvas.drawLine(Offset(cx, cy - crossHalf), Offset(cx, cy + crossHalf), crossPaint);

    if (guideAspectRatio > 0 && w > 0 && h > 0) {
      final guidePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.22)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

      final canvasAspect = w / h;
      late double boxW;
      late double boxH;
      if (canvasAspect > guideAspectRatio) {
        boxH = h;
        boxW = h * guideAspectRatio;
      } else {
        boxW = w;
        boxH = w / guideAspectRatio;
      }
      final left = (w - boxW) / 2;
      final top = (h - boxH) / 2;
      canvas.drawRect(Rect.fromLTWH(left, top, boxW, boxH), guidePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ReticlePainter oldDelegate) =>
      oldDelegate.guideAspectRatio != guideAspectRatio;
}
