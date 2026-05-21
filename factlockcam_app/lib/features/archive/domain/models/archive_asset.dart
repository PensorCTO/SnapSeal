/// Domain view of a sealed digital archive entry for identity lifecycle UI.
class ArchiveAsset {
  const ArchiveAsset({
    required this.assetHash,
    required this.walletAddress,
    required this.isLocallyAvailable,
    required this.isLegacyPlaceholder,
    required this.mimeType,
    required this.createdAt,
    required this.pendingSync,
  });

  final String assetHash;
  final String? walletAddress;
  final bool isLocallyAvailable;

  /// True when the asset was sealed under a prior EVM signing key.
  final bool isLegacyPlaceholder;
  final String? mimeType;
  final DateTime createdAt;
  final bool pendingSync;
}
