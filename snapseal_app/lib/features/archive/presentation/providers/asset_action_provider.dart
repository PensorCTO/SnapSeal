import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/archive/domain/models/media_action_type.dart';
import '../../../../core/di/service_providers.dart';

part 'asset_action_provider.g.dart';

@Riverpod(keepAlive: true)
class AssetAction extends _$AssetAction {
  @override
  FutureOr<void> build() {}

  Future<void> executeAction(MediaActionType action, String assetHash) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard<void>(() async {
      final vaultService = ref.read(vaultServiceProvider);
      final proofLockService = ref.read(proofLockServiceProvider);

      switch (action) {
        case MediaActionType.view:
          // TODO: Return a verified view payload when archive navigation is
          // domain-driven instead of owned by the current presentation route.
          break;
        case MediaActionType.verify:
          await proofLockService.extractForCourier(assetHash);
          break;
        case MediaActionType.delete:
          await vaultService.deleteArchiveItem(assetHash);
          break;
        case MediaActionType.share:
          // TODO: Wire to a sealed-share/courier export service when that
          // ProofLock package boundary exists.
          break;
        case MediaActionType.export:
          // TODO: Wire to certificate/PDF export once binary export is
          // implemented beyond the existing certificate draft text.
          break;
      }
    });
  }
}
