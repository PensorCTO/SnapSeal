import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapseal/app/snapseal_app.dart';
import 'package:snapseal/core/ghost_key/native_enclave_channel.dart';
import 'package:snapseal/domain/services/vault_service.dart';

void main() {
  testWidgets('renders the SnapSeal logon shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nativeEnclaveChannelProvider.overrideWithValue(
            NativeEnclaveChannel(
              signHashForTests: (hash) async => 'test:$hash',
            ),
          ),
        ],
        child: const SnapSealApp(),
      ),
    );

    expect(find.text('SnapSeal'), findsOneWidget);
    expect(find.text('Send Magic Number'), findsOneWidget);
    expect(find.text('Mathematical certainty wallet'), findsOneWidget);
  });
}
