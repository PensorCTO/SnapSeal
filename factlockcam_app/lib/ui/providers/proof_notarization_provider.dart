import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/di/locator.dart';
import '../../domain/blockchain/proof_state.dart';
import '../../domain/services/notarization_monitor_service.dart';
import '../../domain/services/proof_sync_notifier.dart';
import '../controllers/dashboard_controller.dart';

/// Bridges [NotarizationMonitorService.watchAsset] into Riverpod.
final proofNotarizationStateProvider =
    StreamProvider.family<ProofState, String>((ref, assetHash) {
      if (!AppConfig.usePolygonNotarizer) {
        return Stream.value(ProofState.notarized);
      }
      return ref.watch(notarizationMonitorProvider).watchAsset(assetHash);
    });

/// Starts Realtime monitoring for the Polygon saga lifecycle.
final polygonNotarizationLifecycleProvider = Provider<void>((ref) {
  if (!AppConfig.usePolygonNotarizer || AppConfig.isFlutterTest) {
    return;
  }
  final monitor = ref.read(notarizationMonitorProvider);
  monitor.startMonitoring();
  ref.onDispose(monitor.stopMonitoring);
});

/// Refreshes the vault dashboard when relay finalization clears pending_sync.
final polygonProofSyncRefreshProvider = Provider<void>((ref) {
  if (!AppConfig.usePolygonNotarizer || AppConfig.isFlutterTest) {
    return;
  }
  final notifier = getIt<ProofSyncNotifier>();
  final subscription = notifier.onAssetSynced.listen((_) {
    ref.invalidate(dashboardControllerProvider);
  });
  ref.onDispose(subscription.cancel);
});
