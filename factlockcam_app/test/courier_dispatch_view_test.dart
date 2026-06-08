import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:factlockcam/core/di/service_providers.dart';
import 'package:factlockcam/data/models/archive_item.dart';
import 'package:factlockcam/features/archive/presentation/providers/send_proof_provider.dart';
import 'package:factlockcam/ui/controllers/dashboard_controller.dart';
import 'package:factlockcam/ui/mobile/courier_dispatch_view.dart';

import 'test_dependencies.dart';

@Skip('Courier dispatch decommissioned — CourierDispatchView unmounted from hub')
void main() {
  return;
  setUpAll(() async {
    await setupTestDependencies();
  });

  testWidgets('staging grid renders fingerprints and updates selection', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _TwoItemDashboardController.new,
          ),
        ],
        child: MaterialApp(
          home: CourierDispatchView(onBackToHub: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ABC12345'), findsOneWidget);
    expect(find.text('FEDCBA09'), findsOneWidget);

    await tester.tap(find.text('FEDCBA09'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CourierDispatchView)),
    );
    expect(
      container.read(dispatchConsoleProvider).selectedAssetHash,
      'fedcba0987654321',
    );
  });

  testWidgets('continue advances to configure step and back returns', (
    tester,
  ) async {
    var backToHubCalls = 0;

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _TwoItemDashboardController.new,
          ),
        ],
        child: MaterialApp(
          home: CourierDispatchView(onBackToHub: () => backToHubCalls++),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DISPATCH PARAMETERS'), findsNothing);

    await tester.tap(find.text('ABC12345'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.text('DISPATCH PARAMETERS'), findsOneWidget);
    expect(find.text('TRANSMIT PROOF'), findsOneWidget);

    await tester.tap(find.byType(CupertinoNavigationBarBackButton));
    await tester.pumpAndSettle();

    expect(find.text('CONTINUE'), findsOneWidget);
    expect(backToHubCalls, 0);

    await tester.tap(find.byType(CupertinoNavigationBarBackButton));
    await tester.pumpAndSettle();

    expect(backToHubCalls, 1);
  });

  testWidgets('transmit disabled until configure step and password entered', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _TwoItemDashboardController.new,
          ),
        ],
        child: MaterialApp(
          home: CourierDispatchView(onBackToHub: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TRANSMIT PROOF'), findsNothing);

    await tester.tap(find.text('ABC12345'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    final transmitButton = find.widgetWithText(CupertinoButton, 'TRANSMIT PROOF');
    expect(tester.widget<CupertinoButton>(transmitButton).onPressed, isNull);

    await tester.enterText(find.byType(CupertinoTextField), 'secret-pass');
    await tester.pumpAndSettle();
    expect(tester.widget<CupertinoButton>(transmitButton).onPressed, isNotNull);
  });

  testWidgets('transmit passes dispatch params through SendProofRequest', (
    tester,
  ) async {
    final recordingSendProof = _RecordingSendProof();

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _TwoItemDashboardController.new,
          ),
          sendProofProvider.overrideWith(() => recordingSendProof),
        ],
        child: MaterialApp(
          home: CourierDispatchView(onBackToHub: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ABC12345'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30d'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(CupertinoTextField),
      'secret-pass',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('TRANSMIT PROOF'));
    await tester.pumpAndSettle();

    final request = recordingSendProof.lastRequest;
    expect(request, isNotNull);
    expect(request!.maxDownloads, 5);
    expect(request.linkTtlDays, 30);
    expect(request.password, 'secret-pass');
    expect(request.item.assetFingerprint, 'abc1234567890dead');
  });

  testWidgets('send proof failure surfaces friendly courier error copy', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _TwoItemDashboardController.new,
          ),
          sendProofProvider.overrideWith(_FailingSendProof.new),
        ],
        child: MaterialApp(
          home: CourierDispatchView(onBackToHub: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ABC12345'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoTextField), 'pw');
    await tester.pumpAndSettle();
    await tester.tap(find.text('TRANSMIT PROOF'));
    await tester.pumpAndSettle();

    expect(find.text('Could not transmit proof'), findsOneWidget);
    expect(
      find.textContaining('Send Proof is disabled in this build'),
      findsOneWidget,
    );
  });

  testWidgets('empty archive shows seal guidance', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWith(
            _EmptyArchiveDashboardController.new,
          ),
        ],
        child: MaterialApp(
          home: CourierDispatchView(onBackToHub: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Seal media from Picture or Video first'),
      findsOneWidget,
    );
  });
}

class _TwoItemDashboardController extends DashboardController {
  @override
  Future<List<ArchiveItem>> build() async => [
        ArchiveItem(
          assetFingerprint: 'abc1234567890dead',
          encryptedPath: '/tmp/a.seal',
          thumbnailPath: '/tmp/a.jpg',
          byteLength: 100,
          createdAt: DateTime.utc(2026, 6, 1),
          mimeType: 'image/jpeg',
        ),
        ArchiveItem(
          assetFingerprint: 'fedcba0987654321',
          encryptedPath: '/tmp/b.seal',
          thumbnailPath: '/tmp/b.jpg',
          byteLength: 200,
          createdAt: DateTime.utc(2026, 6, 2),
          mimeType: 'video/mp4',
        ),
      ];

  @override
  Future<void> syncPendingInBackground() async {}
}

class _EmptyArchiveDashboardController extends DashboardController {
  @override
  Future<List<ArchiveItem>> build() async => [];

  @override
  Future<void> syncPendingInBackground() async {}
}

class _RecordingSendProof extends SendProof {
  SendProofRequest? lastRequest;

  @override
  FutureOr<SendProofResult?> build() => null;

  @override
  Future<SendProofResult> send(SendProofRequest request) async {
    lastRequest = request;
    return const SendProofResult(
      courierUrl: 'https://archive.example/courier?pkg=test-pkg',
      packageId: 'test-pkg',
      certificatePdfPath: '/tmp/cert.pdf',
    );
  }
}

class _FailingSendProof extends SendProof {
  @override
  FutureOr<SendProofResult?> build() => null;

  @override
  Future<SendProofResult> send(SendProofRequest request) async {
    throw StateError('Send Proof is not available in this build.');
  }
}
