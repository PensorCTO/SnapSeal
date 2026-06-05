import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:factlockcam/ui/web/courier_unlock_view.dart';

import 'test_dependencies.dart';

void main() {
  setUpAll(() async {
    await setupTestDependencies();
  });

  testWidgets('CourierUnlockView shows report affordance when package id present',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CourierUnlockView(packageId: 'test-package-id'),
        ),
      ),
    );

    expect(find.text('Report concerning content'), findsOneWidget);
  });

  testWidgets('CourierUnlockView hides report affordance when package id missing',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CourierUnlockView(packageId: null),
        ),
      ),
    );

    expect(find.text('Report concerning content'), findsNothing);
  });
}
