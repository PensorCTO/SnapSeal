import 'package:flutter_test/flutter_test.dart';

/// Pumps frames and fails if a layout overflow (or other) exception surfaced.
Future<void> expectNoLayoutOverflow(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  final exception = tester.takeException();
  if (exception == null) return;
  expect(
    exception.toString().contains('overflow'),
    isFalse,
    reason: exception.toString(),
  );
}
