import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/di/locator.dart';
import '../../data/local/vault_database.dart';
import '../../data/supabase/seal_ledger_repository.dart';
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
    SealLedgerRepository? sealLedgerRepository,
  })  : _handle = handle,
        _database = database,
        _proofSyncNotifier = proofSyncNotifier,
        _sealLedgerRepository =
            sealLedgerRepository ?? getIt<SealLedgerRepository>();

  final SupabaseClientHandle _handle;
  final VaultDatabase _database;
  final ProofSyncNotifier _proofSyncNotifier;
  final SealLedgerRepository _sealLedgerRepository;

  RealtimeChannel? _channel;
  final _assetControllers = <String, StreamController<ProofState>>{};
  final _seededAssets = <String>{};

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
    _seededAssets.clear();
  }

  @override
  Stream<ProofState> watchAsset(String assetHash) {
    final normalized = assetHash.trim();
    final controller = _assetControllers.putIfAbsent(
      normalized,
      () => StreamController<ProofState>.broadcast(),
    );
    if (!_seededAssets.contains(normalized)) {
      _seededAssets.add(normalized);
      unawaited(_seedAssetState(normalized, controller));
    }
    return controller.stream;
  }

  Future<void> _seedAssetState(
    String assetHash,
    StreamController<ProofState> controller,
  ) async {
    if (controller.isClosed) {
      return;
    }

    final local = await _database.findArchiveItem(assetHash);
    if (local?.chainTxHash != null && local!.chainTxHash!.isNotEmpty) {
      _emitTo(controller, ProofState.notarized);
      return;
    }
    if (local != null && !local.pendingSync) {
      _emitTo(controller, ProofState.notarized);
      return;
    }

    if (!_sealLedgerRepository.isConfigured) {
      _emitTo(controller, ProofState.pendingNotarization);
      return;
    }

    try {
      final remoteStatus = await _sealLedgerRepository.fetchProofNotarizationStatus(
        assetHash,
      );
      if (remoteStatus == null) {
        _emitTo(controller, ProofState.pendingNotarization);
        return;
      }
      final proofState = _mapStatus(remoteStatus);
      _emitTo(controller, proofState);
      if (proofState == ProofState.notarized) {
        final chainTxHash = await _sealLedgerRepository.fetchProofChainTxHash(
          assetHash,
        );
        await _clearLocalPending(assetHash, chainTxHash: chainTxHash);
      }
    } catch (_) {
      _emitTo(controller, ProofState.pendingNotarization);
    }
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

    final chainTxHash = record['chain_tx_hash'] as String?;
    await _clearLocalPending(assetHash, chainTxHash: chainTxHash);
  }

  Future<void> _clearLocalPending(
    String assetHash, {
    String? chainTxHash,
  }) async {
    final item = await _database.findArchiveItem(assetHash);
    if (item == null) {
      return;
    }
    if (!item.pendingSync && item.chainTxHash != null) {
      return;
    }
    await _database.markSyncSucceeded(
      assetFingerprint: assetHash,
      chainTxHash: chainTxHash ?? item.chainTxHash,
    );
    _proofSyncNotifier.notifyAssetSynced(assetHash);
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

  void _emitTo(StreamController<ProofState> controller, ProofState state) {
    if (!controller.isClosed) {
      controller.add(state);
    }
  }
}

final notarizationMonitorProvider = Provider<NotarizationMonitorService>(
  (ref) => getIt<NotarizationMonitorService>(),
);
