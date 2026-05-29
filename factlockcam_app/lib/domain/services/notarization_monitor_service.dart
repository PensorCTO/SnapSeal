import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web3dart/web3dart.dart';

import '../../core/config/app_config.dart';
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

  /// Polls Polygon RPC for pending transaction receipts.
  Future<void> checkPendingPolygonTransactions();
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

  @override
  Future<void> checkPendingPolygonTransactions() async {}
}

/// Subscribes to Supabase Realtime `UPDATE` events on `proof_ledger`
/// AND polls Polygon RPC for pending transaction receipts.
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
            sealLedgerRepository ?? getIt<SealLedgerRepository>(); // ignore: inference_failure_on_instance_creation

  final SupabaseClientHandle _handle;
  final VaultDatabase _database;
  final ProofSyncNotifier _proofSyncNotifier;
  final SealLedgerRepository _sealLedgerRepository;

  RealtimeChannel? _channel;
  Web3Client? _web3Client;
  final _assetControllers = <String, StreamController<ProofState>>{};
  final _seededAssets = <String>{};

  @override
  void startMonitoring() {
    final client = _handle.client;
    if (client == null || _channel != null) {
      return;
    }

    // Do not block the first frame on Realtime socket connect.
    unawaited(_startRealtimeSubscription(client));
    _initWeb3Client();
  }

  Future<void> _startRealtimeSubscription(SupabaseClient client) async {
    if (_channel != null) {
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

  /// Initializes the Web3Client from the POLYGON_RPC_URL dart-define.
  void _initWeb3Client() {
    final rpcUrl = AppConfig.polygonRpcUrl;
    if (rpcUrl == null || rpcUrl.isEmpty) {
      return;
    }
    _web3Client = Web3Client(rpcUrl, http.Client());
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
    _web3Client?.dispose();
    _web3Client = null;
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

  @override
  Future<void> checkPendingPolygonTransactions() async {
    final web3 = _web3Client;
    if (web3 == null) {
      return;
    }

    if (!_sealLedgerRepository.isConfigured) {
      return;
    }

    try {
      // Query proof_ledger for pending transactions that have a chain_tx_hash
      // (The relay may have broadcast but the DB row still says pending_notarization)
      final user = _handle.client?.auth.currentUser;
      if (user == null) {
        return;
      }

      // Fetch pending asset hashes from the local database
      final pendingItems = await _database.listPendingArchiveItems();

      for (final item in pendingItems) {
        final assetHash = item.assetFingerprint;
        if (assetHash.isEmpty) {
          continue;
        }

        // Try to get the chain tx hash from the remote ledger
        final chainTxHash = await _sealLedgerRepository
            .fetchProofChainTxHash(assetHash);

        if (chainTxHash == null || chainTxHash.isEmpty) {
          continue;
        }

        try {
          final receipt =
              await web3.getTransactionReceipt(chainTxHash);

          if (receipt != null) {
            // Transaction has been mined
            final confirmed =
                receipt.status != null && receipt.status!;

            if (confirmed) {
              await _clearLocalPending(
                assetHash,
                chainTxHash: chainTxHash,
              );
              _emit(assetHash, ProofState.notarized);
            } else {
              // Transaction reverted
              _emit(assetHash, ProofState.failed);
            }
          }
          // receipt == null means still pending — skip
        } catch (_) {
          // RPC call failed (network error, tx not found, etc.) — skip
        }
      }
    } catch (_) {
      // General error — skip this polling cycle
    }
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
      final remoteStatus =
          await _sealLedgerRepository.fetchProofNotarizationStatus(
        assetHash,
      );
      if (remoteStatus == null) {
        _emitTo(controller, ProofState.pendingNotarization);
        return;
      }
      final proofState = _mapStatus(remoteStatus);
      _emitTo(controller, proofState);
      if (proofState == ProofState.notarized) {
        final chainTxHash =
            await _sealLedgerRepository.fetchProofChainTxHash(
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
