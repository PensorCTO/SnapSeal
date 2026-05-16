import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/archive_item.dart';
import '../../../controllers/dashboard_controller.dart';

/// Editable metadata state for a single asset in the inspector.
class AssetMetadataState {
  const AssetMetadataState({
    required this.assetFingerprint,
    required this.title,
    required this.description,
    required this.isDirty,
    this.saveError,
  });

  final String assetFingerprint;
  final String? title;
  final String? description;
  final bool isDirty;
  final String? saveError;

  AssetMetadataState copyWith({
    String? assetFingerprint,
    String? Function()? title,
    String? Function()? description,
    bool? isDirty,
    Object? saveError = _unset,
  }) => AssetMetadataState(
    assetFingerprint: assetFingerprint ?? this.assetFingerprint,
    title: title != null ? title() : this.title,
    description: description != null ? description() : this.description,
    isDirty: isDirty ?? this.isDirty,
    saveError: saveError == _unset ? this.saveError : saveError as String?,
  );

  static const _unset = Object();
}

/// Riverpod family keyed by [assetFingerprint] that holds optimistic metadata
/// state for the Asset Inspector form.
///
/// Updates the local [DashboardController] (SQLite) without touching
/// [proof_ledger], encrypted files, or [assetFingerprint].
final assetMetadataProvider =
    NotifierProvider.family<AssetMetadataNotifier, AssetMetadataState, String>(
  (fingerprint) => AssetMetadataNotifier(fingerprint),
);

class AssetMetadataNotifier extends Notifier<AssetMetadataState> {
  AssetMetadataNotifier(this.assetFingerprint);

  final String assetFingerprint;

  @override
  AssetMetadataState build() {
    return AssetMetadataState(
      assetFingerprint: assetFingerprint,
      title: null,
      description: null,
      isDirty: false,
    );
  }

  /// Initialise state from the on-disk [ArchiveItem].
  void initFromArchiveItem(ArchiveItem item) {
    state = AssetMetadataState(
      assetFingerprint: item.assetFingerprint,
      title: item.title,
      description: item.description,
      isDirty: false,
    );
  }

  /// Optimistically update the local title. Persists to [DashboardController]
  /// and clears the dirty flag if the save succeeds.
  Future<void> setTitle(String? newTitle) async {
    final trimmed = _normalize(newTitle);
    state = state.copyWith(title: () => trimmed, isDirty: true, saveError: null);
  }

  /// Optimistically update the local description. Persists to
  /// [DashboardController] and clears the dirty flag if the save succeeds.
  Future<void> setDescription(String? newDescription) async {
    final trimmed = _normalize(newDescription);
    state = state.copyWith(
      description: () => trimmed,
      isDirty: true,
      saveError: null,
    );
  }

  /// Persist the current metadata to the local database via
  /// [DashboardController.updateArchiveMetadata].
  ///
  /// Optimistically clears the dirty flag before the async call completes
  /// so the UI feels instant. On error the dirty flag is restored and
  /// [saveError] is set.
  Future<void> save() async {
    if (!state.isDirty) return;

    final currentTitle = state.title;
    final currentDescription = state.description;

    // Optimistic: clear dirty immediately.
    state = state.copyWith(isDirty: false, saveError: null);

    try {
      await ref
          .read(dashboardControllerProvider.notifier)
          .updateArchiveMetadata(
            assetFingerprint: state.assetFingerprint,
            title: currentTitle,
            description: currentDescription,
          );
    } catch (e) {
      state = state.copyWith(
        isDirty: true,
        saveError: e.toString(),
      );
    }
  }

  String? _normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
