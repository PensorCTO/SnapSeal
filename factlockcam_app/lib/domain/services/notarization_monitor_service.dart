import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/di/locator.dart';
import '../../data/local/vault_database.dart';
import '../../data/supabase/supabase_client_handle.dart';
import '../blockchain/proof_state.dart';
import '../services/proof_sync_notifier.dart';

/// Realtime monitor for asynchronous on-chain notarization completion.
abstract class NotarizationMonitorService {
  void startMonitoring();

  void stopMonitoring();

  Stream<ProofState> watchAsset(String assetHash);
}

/// No-op monitor — simulated chain resolves synchronously.
class SimulatedNotarizationMonitorService
    implements NotarizationMonitorService {
  @override
  void startMonitoring() {}

  @override
  void stopMonitoring() {}

  @override
  Stream<ProofState> watchAsset(String assetHash) =>
      Stream.value(ProofState.notarized);
}

/// Subscribes to Supabase Realtime `UPDATE` events on `proof_ledger`.
class PolygonNotarizationMonitorService
    implements NotarizationMonitorService {
  PolygonNotarizationMonitorService({
    required SupabaseClientHandle handle,
    required VaultDatabase database,
    required ProofSyncNotifier proofSyncNotifier,
  })  : _handle = handle,
        _database = database,
        _proofSyncNotifier = proofSyncNotifier;

  final SupabaseClientHandle _handle;
  final VaultDatabase _database;
  final ProofSyncNotifier _proofSyncNotifier;

  RealtimeChannel? _channel;
  final _assetControllers = <String, StreamController<ProofState>>{};

  @override
  void startMonitoring() {
    final client = _handle.client;
    if (client == null || _channel != null) {
      return;
    }

    _channel = client
        .channel('proof-ledger-polygon-monitor')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'proof_ledger',
          callback: (payload) {
            unawaited(_handleLedgerUpdate(payload.newRecord));
          },
        )
        .subscribe();
  }

  @override
  void stopMonitoring() {
    final client = _handle.client;
    final channel = _channel;
    _channel = null;
    if (client != null && channel != null) {
      client.removeChannel(channel);
    }
    for (final controller in _assetControllers.values) {
      unawaited(controller.close());
    }
    _assetControllers.clear();
  }

  @override
  Stream<ProofState> watchAsset(String assetHash) {
    final normalized = assetHash.trim();
    return _assetControllers
        .putIfAbsent(
          normalized,
          () => StreamController<ProofState>.broadcast(),
        )
        .stream;
  }

  Future<void> _handleLedgerUpdate(Map<String, dynamic> record) async {
    final assetHash = record['asset_hash'] as String?;
    if (assetHash == null || assetHash.isEmpty) {
      return;
    }

    final status = record['notarization_status'] as String? ?? 'notarized';
    final proofState = _mapStatus(status);
    _emit(assetHash, proofState);

    if (proofState != ProofState.notarized) {
      return;
    }

    await _clearLocalPending(assetHash);
  }

  Future<void> _clearLocalPending(String assetHash) async {
    final item = await _database.findArchiveItem(assetHash);
    if (item != null && item.pendingSync) {
      await _database.markSyncSucceeded(assetFingerprint: assetHash);
      _proofSyncNotifier.notifyAssetSynced(assetHash);
    }
  }

  ProofState _mapStatus(String status) {
    switch (status) {
      case 'pending_notarization':
        return ProofState.pendingNotarization;
      case 'failed':
        return ProofState.failed;
      case 'notarized':
        return ProofState.notarized;
      default:
        return ProofState.pendingNotarization;
    }
  }

  void _emit(String assetHash, ProofState state) {
    final controller = _assetControllers[assetHash];
    if (controller != null && !controller.isClosed) {
      controller.add(state);
    }
  }
}

final notarizationMonitorProvider = Provider<NotarizationMonitorService>(
  (ref) => getIt<NotarizationMonitorService>(),
);
