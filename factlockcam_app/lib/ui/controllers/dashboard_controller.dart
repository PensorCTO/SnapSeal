import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/vault_database.dart';
import '../../data/models/archive_item.dart';
import '../../domain/services/vault_service.dart';
import '../mobile/vault/providers/thumbnail_cache_provider.dart';

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, List<ArchiveItem>>(
      DashboardController.new,
    );

/// Single process-wide coordinator so all callers serialize through one mutex.
final PendingSyncCoordinator _pendingSyncCoordinator = PendingSyncCoordinator();

final pendingSyncCoordinatorProvider = Provider<PendingSyncCoordinator>(
  (ref) => _pendingSyncCoordinator,
);

class PendingSyncCoordinator {
  Future<void>? _inFlight;

  Future<void> run(Future<void> Function() action) {
    final inFlight = _inFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final completer = Completer<void>();
    _inFlight = completer.future;

    () async {
      try {
        await action();
        if (!completer.isCompleted) {
          completer.complete();
        }
      } catch (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      } finally {
        if (identical(_inFlight, completer.future)) {
          _inFlight = null;
        }
      }
    }();

    return completer.future;
  }
}

class DashboardController extends AsyncNotifier<List<ArchiveItem>> {
  @override
  Future<List<ArchiveItem>> build() async {
    return _loadResolvedArchive();
  }

  Future<List<ArchiveItem>> _loadResolvedArchive() async {
    return ref.read(vaultServiceProvider).listArchiveItems();
  }

  Future<void> refreshArchive() async {
    state = AsyncData(await _loadResolvedArchive());
  }

  /// Explicit background trigger invoked by the view lifecycle.
  Future<void> syncPendingInBackground() async {
    final coordinator = ref.read(pendingSyncCoordinatorProvider);
    await coordinator.run(() async {
      final pending = await ref
          .read(vaultDatabaseProvider)
          .listPendingArchiveItems();
      if (pending.isEmpty) {
        return;
      }

      final vault = ref.read(vaultServiceProvider);
      var changed = false;
      for (final item in pending) {
        try {
          final cleared = await vault.retryPendingRemoteSync(
            item.assetFingerprint,
          );
          if (cleared) {
            changed = true;
          }
        } catch (_) {
          // Intentionally ignored: dashboard must stay responsive during sync attempts.
        }
      }

      if (changed) {
        final refreshed = await _loadResolvedArchive();
        state = AsyncData(refreshed);
      }
    });
  }

  Future<void> burnLocalWallet() async {
    await ref.read(vaultServiceProvider).burnLocalWallet();
    state = const AsyncData([]);
  }

  Future<void> deleteArchiveItem(String assetFingerprint) async {
    await ref.read(vaultServiceProvider).deleteArchiveItem(assetFingerprint);
    ref.invalidate(thumbnailCacheProvider(assetFingerprint));
    state = AsyncData(await _loadResolvedArchive());
  }

  Future<void> updateArchiveMetadata({
    required String assetFingerprint,
    required String? title,
    required String? description,
  }) async {
    final db = ref.read(vaultDatabaseProvider);
    final existing = await db.findArchiveItem(assetFingerprint);
    if (existing == null) {
      return;
    }

    final normalizedTitle = _normalizeMetadataField(title);
    final normalizedDescription = _normalizeMetadataField(description);
    if (normalizedTitle == existing.title &&
        normalizedDescription == existing.description) {
      return;
    }

    await ref.read(vaultServiceProvider).updateArchiveMetadata(
          assetFingerprint: assetFingerprint,
          title: title,
          description: description,
        );

    final updated = existing.copyWith(
      title: normalizedTitle,
      description: normalizedDescription,
    );

    final current = state.asData?.value;
    if (current == null) {
      state = AsyncData(await _loadResolvedArchive());
      return;
    }

    final refreshed = current
        .map(
          (item) => item.assetFingerprint == assetFingerprint ? updated : item,
        )
        .toList(growable: false);
    state = AsyncData(refreshed);
  }

  String? _normalizeMetadataField(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
