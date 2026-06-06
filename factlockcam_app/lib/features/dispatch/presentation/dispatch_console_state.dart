/// Staging and policy selections for the mobile Dispatch Console.
class DispatchConsoleState {
  const DispatchConsoleState({
    this.selectedAssetHash,
    this.maxDownloads = 3,
    this.linkTtlDays = 7,
  });

  final String? selectedAssetHash;

  /// Presets: 1, 3, 5 — aligns with courier_packages default.
  final int maxDownloads;

  /// Presets: 1, 7, 30 days — aligns with courier_packages default expiry.
  final int linkTtlDays;

  static const List<int> maxDownloadPresets = [1, 3, 5];
  static const List<int> linkTtlPresets = [1, 7, 30];

  DispatchConsoleState copyWith({
    String? selectedAssetHash,
    bool clearSelectedAssetHash = false,
    int? maxDownloads,
    int? linkTtlDays,
  }) {
    return DispatchConsoleState(
      selectedAssetHash: clearSelectedAssetHash
          ? null
          : (selectedAssetHash ?? this.selectedAssetHash),
      maxDownloads: maxDownloads ?? this.maxDownloads,
      linkTtlDays: linkTtlDays ?? this.linkTtlDays,
    );
  }
}
