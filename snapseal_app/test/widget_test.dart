import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapseal/app/snapseal_app.dart';

void main() {
  testWidgets('renders the SnapSeal logon shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SnapSealApp()));

    expect(find.text('SnapSeal'), findsOneWidget);
    expect(find.text('Send Magic Link'), findsOneWidget);
    expect(find.text('Mathematical certainty wallet'), findsOneWidget);
  });
}
