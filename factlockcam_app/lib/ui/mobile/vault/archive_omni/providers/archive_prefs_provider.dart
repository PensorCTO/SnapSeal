import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/models/archive_item.dart';
import '../../../../controllers/dashboard_controller.dart';

// ── Enums ───────────────────────────────────────────────────────────────────

enum ArchiveViewMode { chronology, grid }

enum ArchiveFilterType { all, photos, videos, pending }

// ── State class ─────────────────────────────────────────────────────────────

class ArchivePrefsState {
  const ArchivePrefsState({
    this.viewMode = ArchiveViewMode.chronology,
    this.filterType = ArchiveFilterType.all,
  });

  final ArchiveViewMode viewMode;
  final ArchiveFilterType filterType;

  ArchivePrefsState copyWith({
    ArchiveViewMode? viewMode,
    ArchiveFilterType? filterType,
  }) {
    return ArchivePrefsState(
      viewMode: viewMode ?? this.viewMode,
      filterType: filterType ?? this.filterType,
    );
  }
}

// ── Notifier ────────────────────────────────────────────────────────────────

class ArchivePrefsNotifier extends Notifier<ArchivePrefsState> {
  @override
  ArchivePrefsState build() => const ArchivePrefsState();

  void setViewMode(ArchiveViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void setFilterType(ArchiveFilterType type) {
    state = state.copyWith(filterType: type);
  }
}

// ── Providers ───────────────────────────────────────────────────────────────

final archivePrefsProvider =
    NotifierProvider<ArchivePrefsNotifier, ArchivePrefsState>(
  ArchivePrefsNotifier.new,
);

/// Computed provider that reads [dashboardControllerProvider] and
/// [archivePrefsProvider] to yield the filtered + sorted item list.
final filteredArchiveProvider = Provider<List<ArchiveItem>>((ref) {
  final items = ref.watch(dashboardControllerProvider).asData?.value ?? [];
  final prefs = ref.watch(archivePrefsProvider);

  List<ArchiveItem> result = List.of(items);

  // Apply filter
  switch (prefs.filterType) {
    case ArchiveFilterType.all:
      break;
    case ArchiveFilterType.photos:
      result = result
          .where((item) => !(item.mimeType?.startsWith('video/') ?? false))
          .toList(growable: false);
      break;
    case ArchiveFilterType.videos:
      result = result
          .where((item) => item.mimeType?.startsWith('video/') ?? false)
          .toList(growable: false);
      break;
    case ArchiveFilterType.pending:
      result =
          result.where((item) => item.pendingSync).toList(growable: false);
      break;
  }

  // Sort by createdAt descending (newest first)
  result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return result;
});
