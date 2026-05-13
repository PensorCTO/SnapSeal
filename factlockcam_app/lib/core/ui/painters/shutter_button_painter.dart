import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Paints a machined-metal capture control with a six-blade iris aperture.
class ShutterIrisPainter extends CustomPainter {
  const ShutterIrisPainter({
    required this.closeProgress,
    required this.recordFill,
    required this.verifiedFlash,
  });

  final double closeProgress;
  final double recordFill;
  final double verifiedFlash;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final outerRadius = radius - 1.5;
    final apertureRadius = radius * 0.49;
    final clampedClose = closeProgress.clamp(0.0, 1.0);
    final clampedRecord = recordFill.clamp(0.0, 1.0);
    final clampedVerified = verifiedFlash.clamp(0.0, 1.0);

    _drawOuterRing(canvas, center, outerRadius);
    _drawApertureFill(
      canvas,
      center,
      apertureRadius,
      clampedRecord,
      clampedVerified,
    );
    _drawIrisBlades(canvas, center, radius, clampedClose);
    _drawInnerRing(canvas, center, apertureRadius);
  }

  void _drawOuterRing(Canvas canvas, Offset center, double outerRadius) {
    final ringRect = Rect.fromCircle(center: center, radius: outerRadius);
    final ringPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          AppColors.titaniumHighlight,
          AppColors.titaniumPanel,
          Color(0xFF050505),
        ],
        stops: [0.56, 0.78, 1],
      ).createShader(ringRect)
      ..style = PaintingStyle.fill;

    final innerCutoutPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;

    canvas.saveLayer(ringRect, Paint());
    canvas.drawCircle(center, outerRadius, ringPaint);
    canvas.drawCircle(center, outerRadius - 10, innerCutoutPaint);
    canvas.restore();

    final strokePaint = Paint()
      ..color = AppColors.starkWhite.withValues(alpha: 0.78)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, outerRadius, strokePaint);
    canvas.drawCircle(center, outerRadius - 10, strokePaint..strokeWidth = 1);

    final tickPaint = Paint()
      ..color = AppColors.starkWhite.withValues(alpha: 0.34)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.square;
    for (var i = 0; i < 12; i += 1) {
      final theta = (math.pi * 2 / 12) * i;
      final start = Offset(
        center.dx + math.cos(theta) * (outerRadius - 7),
        center.dy + math.sin(theta) * (outerRadius - 7),
      );
      final end = Offset(
        center.dx + math.cos(theta) * (outerRadius - 2),
        center.dy + math.sin(theta) * (outerRadius - 2),
      );
      canvas.drawLine(start, end, tickPaint);
    }
  }

  void _drawApertureFill(
    Canvas canvas,
    Offset center,
    double apertureRadius,
    double record,
    double verified,
  ) {
    if (record == 0 && verified == 0) return;

    final color = Color.lerp(
      AppColors.kineticGreen.withValues(alpha: 0.78 * record),
      AppColors.verifiedNeon.withValues(alpha: 0.95),
      verified,
    )!;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      center,
      apertureRadius * math.max(record, verified),
      fillPaint,
    );
  }

  void _drawIrisBlades(
    Canvas canvas,
    Offset center,
    double radius,
    double progress,
  ) {
    const bladeCount = 6;
    final bladePaint = Paint()
      ..color = AppColors.titaniumPanel.withValues(alpha: 0.96)
      ..style = PaintingStyle.fill;
    final edgePaint = Paint()
      ..color = AppColors.starkWhite.withValues(alpha: 0.34)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < bladeCount; i += 1) {
      final baseAngle = (math.pi * 2 / bladeCount) * i - math.pi / 2;
      final sweep = math.pi / 3.15;
      final rotation = progress * math.pi / 8;
      final inner = radius * (0.34 - 0.12 * progress);
      final outer = radius * 0.73;

      final points = [
        _polar(center, baseAngle - sweep / 2 + rotation, inner),
        _polar(center, baseAngle + sweep / 2 + rotation, outer),
        _polar(center, baseAngle + sweep * 1.28 + rotation, outer),
        _polar(center, baseAngle + sweep * 0.24 + rotation, inner * 0.74),
      ];

      final blade = Path()..addPolygon(points, true);
      canvas.drawPath(blade, bladePaint);
      canvas.drawLine(points.first, points[1], edgePaint);
    }
  }

  void _drawInnerRing(Canvas canvas, Offset center, double apertureRadius) {
    final aperturePaint = Paint()
      ..color = AppColors.starkWhite.withValues(alpha: 0.54)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, apertureRadius, aperturePaint);
  }

  Offset _polar(Offset center, double angle, double radius) {
    return Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
  }

  @override
  bool shouldRepaint(covariant ShutterIrisPainter oldDelegate) {
    return oldDelegate.closeProgress != closeProgress ||
        oldDelegate.recordFill != recordFill ||
        oldDelegate.verifiedFlash != verifiedFlash;
  }
}
