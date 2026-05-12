import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:snapseal/core/archive/domain/models/media_action_type.dart';
import 'package:snapseal/core/archive/domain/services/asset_action_registry.dart';
import 'package:snapseal/core/archive/presentation/widgets/universal_asset_toolbar.dart';

void main() {
  test('registry maps current media type strings to archive actions', () {
    expect(AssetActionRegistry.getActionsForType('image/jpeg'), [
      MediaActionType.view,
      MediaActionType.verify,
      MediaActionType.delete,
    ]);
    expect(AssetActionRegistry.getActionsForType('video/mp4'), [
      MediaActionType.view,
      MediaActionType.verify,
      MediaActionType.delete,
    ]);
    expect(AssetActionRegistry.getActionsForType('application/pdf'), [
      MediaActionType.view,
      MediaActionType.verify,
      MediaActionType.export,
      MediaActionType.share,
      MediaActionType.delete,
    ]);
  });

  testWidgets('toolbar renders video view as play action', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CupertinoApp(
          home: UniversalAssetToolbar(
            assetHash: 'abc123',
            mediaType: 'video/mp4',
          ),
        ),
      ),
    );

    expect(find.text('Play video'), findsOneWidget);
    expect(find.text('Verify integrity'), findsOneWidget);
    expect(find.text('Delete from this device'), findsOneWidget);
  });

  testWidgets('toolbar renders photo view action', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CupertinoApp(
          home: UniversalAssetToolbar(
            assetHash: 'abc123',
            mediaType: 'image/jpeg',
          ),
        ),
      ),
    );

    expect(find.text('View full-size photo'), findsOneWidget);
    expect(find.text('Verify integrity'), findsOneWidget);
    expect(find.text('Delete from this device'), findsOneWidget);
  });
}
