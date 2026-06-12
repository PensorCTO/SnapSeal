@Skip('Secure Comm unmounted from hub — widget tests retained for orphaned module')
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:factlockcam/features/dispatch/presentation/archive_access_control_panel.dart';
import 'package:factlockcam/features/dispatch/presentation/dispatch_console_state.dart';
import 'package:factlockcam/features/dispatch/presentation/secure_comm_capture_provider.dart';
import 'package:factlockcam/features/dispatch/presentation/secure_comm_capture_state.dart';

import 'test_dependencies.dart';

void main() {
  setUpAll(() async {
    await setupTestDependencies();
  });

  testWidgets('Access Control Panel renders Archive lexicon labels', (
    tester,
  ) async {
    final passwordController = TextEditingController();
    final passwordFocusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArchiveAccessControlPanel(
            passwordController: passwordController,
            passwordFocusNode: passwordFocusNode,
            obscurePassword: true,
            onToggleObscurePassword: () {},
            maxDownloads: 3,
            linkTtlDays: 7,
            onMaxDownloadsChanged: (_) {},
            onLinkTtlChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('ACCESS CONTROL PANEL'), findsOneWidget);
    expect(find.text('Recipient Key'), findsOneWidget);
    expect(find.text('Link Lifespan'), findsOneWidget);
    expect(find.text('Exposure Limit'), findsOneWidget);
    expect(find.text('DISPATCH PARAMETERS'), findsNothing);

    passwordController.dispose();
    passwordFocusNode.dispose();
  });

  testWidgets('Recipient Key hidden while archive anchor pending', (
    tester,
  ) async {
    final passwordController = TextEditingController();
    final passwordFocusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArchiveAccessControlPanel(
            passwordEnabled: false,
            passwordController: passwordController,
            passwordFocusNode: passwordFocusNode,
            obscurePassword: true,
            onToggleObscurePassword: () {},
            maxDownloads: 3,
            linkTtlDays: 7,
            onMaxDownloadsChanged: (_) {},
            onLinkTtlChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Waiting for archive anchor…'), findsOneWidget);
    expect(find.byType(CupertinoTextField), findsNothing);

    passwordController.dispose();
    passwordFocusNode.dispose();
  });

  test('secureCommCaptureProvider tracks anchoring and seal success', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(secureCommCaptureProvider.notifier);
    notifier.beginAnchoring(previewVideoPath: '/tmp/preview.mp4');

    expect(
      container.read(secureCommCaptureProvider).phase,
      SecureCommCapturePhase.anchoringArchive,
    );

    notifier.sealSucceeded('abc123hash');
    final state = container.read(secureCommCaptureProvider);
    expect(state.phase, SecureCommCapturePhase.reviewAndDispatch);
    expect(state.assetFingerprint, 'abc123hash');
    expect(state.canTransmit, isTrue);
  });

  test('dispatch presets align with courier RPC defaults', () {
    expect(DispatchConsoleState.maxDownloadPresets, [1, 3, 5]);
    expect(DispatchConsoleState.linkTtlPresets, [1, 7, 30]);
    expect(const DispatchConsoleState().maxDownloads, 3);
    expect(const DispatchConsoleState().linkTtlDays, 7);
  });
}
