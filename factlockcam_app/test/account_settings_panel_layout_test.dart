import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:factlockcam/ui/controllers/auth_controller.dart';
import 'package:factlockcam/ui/mobile/archive/account_settings_panel.dart';

import 'helpers/layout_test_helpers.dart';
import 'test_dependencies.dart';

void main() {
  setUpAll(() async {
    await setupTestDependencies();
  });

  Future<void> pumpAccountPanel(
    WidgetTester tester, {
    required Size surface,
  }) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_IdleAuthController.new),
        ],
        child: MaterialApp(
          home: AccountSettingsPanel(onBackToHub: () {}),
        ),
      ),
    );
    await expectNoLayoutOverflow(tester);
  }

  testWidgets('account settings portrait scrolls without overflow', (
    tester,
  ) async {
    await pumpAccountPanel(tester, surface: const Size(390, 844));

    expect(find.text('ACCOUNT & SETTINGS'), findsOneWidget);
    expect(find.text('LOG OUT'), findsOneWidget);
    expect(find.text('BURN ACCOUNT'), findsOneWidget);
  });

  testWidgets('account settings landscape avoids RenderFlex overflow', (
    tester,
  ) async {
    await pumpAccountPanel(tester, surface: const Size(844, 390));

    expect(find.text('TERMS OF SERVICE'), findsOneWidget);
    expect(find.text('LOG OUT'), findsOneWidget);
  });
}

class _IdleAuthController extends AuthController {
  @override
  AuthUiState build() => const AuthUiState(isConfigured: false);
}
