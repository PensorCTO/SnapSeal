import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:snapseal/core/ui/painters/reticle_painter.dart';
import 'package:snapseal/ui/views/camera/acquisition_mode.dart';
import 'package:snapseal/ui/views/camera/telemetry_overlay.dart';

void main() {
  test('ReticlePainter shouldRepaint only when guideAspectRatio changes', () {
    final a = ReticlePainter(guideAspectRatio: 16 / 9);
    final b = ReticlePainter(guideAspectRatio: 16 / 9);
    final c = ReticlePainter(guideAspectRatio: 2.35);
    expect(a.shouldRepaint(b), isFalse);
    expect(a.shouldRepaint(c), isTrue);
  });

  testWidgets('TelemetryOverlay shows GPS placeholder and abbreviated hash', (
    tester,
  ) async {
    const hash = 'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TelemetryOverlay(
            acquisitionMode: AcquisitionMode.photo,
            isRecording: false,
            isSealing: false,
            liveHashHex: hash,
          ),
        ),
      ),
    );

    expect(find.textContaining('GPS --'), findsOneWidget);
    expect(find.textContaining('SHA256 0xabcdef01'), findsOneWidget);
    expect(find.textContaining('23456789'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
  });

  testWidgets('TelemetryOverlay shows STBY mode tag when idle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TelemetryOverlay(
            acquisitionMode: AcquisitionMode.video,
            isRecording: false,
            isSealing: false,
          ),
        ),
      ),
    );

    expect(find.textContaining('[VIDEO]'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
  });
}
