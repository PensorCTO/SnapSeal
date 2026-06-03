import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:factlockcam/core/ui/painters/reticle_painter.dart';
import 'package:factlockcam/features/archive_quota/domain/models/quota_state.dart';
import 'package:factlockcam/features/archive_quota/presentation/providers/quota_state_provider.dart';
import 'package:factlockcam/ui/mobile/camera/acquisition_mode.dart';
import 'package:factlockcam/ui/mobile/camera/telemetry_overlay.dart';

Widget _telemetryHarness(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

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
    const hash =
        'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';

    await tester.pumpWidget(
      _telemetryHarness(
        const TelemetryOverlay(
          acquisitionMode: AcquisitionMode.photo,
          isRecording: false,
          archivingCount: 0,
          liveHashHex: hash,
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
      _telemetryHarness(
        const TelemetryOverlay(
          acquisitionMode: AcquisitionMode.video,
          isRecording: false,
          archivingCount: 0,
        ),
      ),
    );

    expect(find.textContaining('[VIDEO]'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
  });

  testWidgets('TelemetryOverlay shows PROOFS gas gauge when quota is set', (
    tester,
  ) async {
    const quota = QuotaState(
      proProofsRemaining: 34,
      proProofsBase: 50,
      egressCreditsBalance: 12,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quotaStateProvider.overrideWith(() => _FixedQuotaStateNotifier(quota)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TelemetryOverlay(
              acquisitionMode: AcquisitionMode.photo,
              isRecording: false,
              archivingCount: 0,
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('PROOFS: 34/50'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
  });
}

class _FixedQuotaStateNotifier extends QuotaStateNotifier {
  _FixedQuotaStateNotifier(this._fixed);

  final QuotaState _fixed;

  @override
  QuotaState? build() => _fixed;
}
