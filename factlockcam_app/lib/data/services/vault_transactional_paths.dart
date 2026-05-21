/// Final + staging paths for prepare/commit file mutations.
class VaultTransactionalPaths {
  const VaultTransactionalPaths({
    required this.encryptedFinalPath,
    required this.thumbnailFinalPath,
    required this.encryptedStagingPath,
    required this.thumbnailStagingPath,
  });

  final String encryptedFinalPath;
  final String thumbnailFinalPath;
  final String encryptedStagingPath;
  final String thumbnailStagingPath;
}
