import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:factlockcam/core/marketing/approved_pitch.dart';
import 'package:factlockcam/ui/web/courier_unlock_notifier.dart';
import 'package:factlockcam/ui/web/courier_unlock_phase.dart';
import 'package:factlockcam/ui/web/courier_unlock_view.dart';
import 'package:factlockcam/ui/web/widgets/hash_cascade_ticker.dart';

import 'test_dependencies.dart';

@Skip('Web courier unlock decommissioned — CourierUnlockView removed from router')
void main() {
  return;
  setUpAll(() async {
    await setupTestDependencies();
  });

  testWidgets('CourierUnlockView shows Secure Communications Console gate',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CourierUnlockView(packageId: 'test-package-id'),
        ),
      ),
    );

    expect(find.text(courierConsoleHeadline), findsOneWidget);
    expect(find.text('Unlock Archive package'), findsOneWidget);
    expect(find.text('Report concerning content'), findsOneWidget);
  });

  testWidgets('HashCascadeTicker renders alignment copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HashCascadeTicker(targetHash: 'abc123'),
        ),
      ),
    );

    expect(find.text('ALIGNING DIGITAL DNA'), findsOneWidget);
    expect(find.text('VERIFYING…'), findsOneWidget);
  });

  testWidgets('CourierUnlockView hides gate during cascade phase', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courierUnlockProvider.overrideWith(
            () => _CascadeTestNotifier(),
          ),
        ],
        child: const MaterialApp(
          home: CourierUnlockView(packageId: 'test-package-id'),
        ),
      ),
    );

    expect(find.text(courierConsoleHeadline), findsNothing);
    expect(find.text('ALIGNING DIGITAL DNA'), findsOneWidget);
  });
}

class _CascadeTestNotifier extends CourierUnlockNotifier {
  @override
  CourierUnlockState build() {
    return const CourierUnlockState(
      phase: CourierUnlockPhase.cascadeAnimation,
      targetAssetHash: 'deadbeef',
    );
  }
}
