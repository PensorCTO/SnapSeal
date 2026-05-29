import 'package:factlockcam/ui/mobile/settings/burn_account_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_dependencies.dart';

void main() {
  setUpAll(() async {
    await setupTestDependencies();
  });

  testWidgets('burn button disabled until checkbox and OBLITERATE typed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CupertinoApp(home: BurnAccountView()),
      ),
    );
    await tester.pumpAndSettle();

    final burnButton = find.widgetWithText(
      CupertinoButton,
      'BURN ACCOUNT PERMANENTLY',
    );
    expect(burnButton, findsOneWidget);

    final button = tester.widget<CupertinoButton>(burnButton);
    expect(button.onPressed, isNull);

    await tester.tap(find.byType(CupertinoCheckbox));
    await tester.pumpAndSettle();
    expect(tester.widget<CupertinoButton>(burnButton).onPressed, isNull);

    await tester.enterText(
      find.byType(CupertinoTextField),
      BurnAccountView.confirmationToken,
    );
    await tester.pumpAndSettle();

    expect(tester.widget<CupertinoButton>(burnButton).onPressed, isNotNull);
  });
}
