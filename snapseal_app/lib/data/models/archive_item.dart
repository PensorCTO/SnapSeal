class ArchiveItem {
  const ArchiveItem({
    required this.assetFingerprint,
    required this.encryptedPath,
    required this.thumbnailPath,
    required this.byteLength,
    required this.createdAt,
    this.pendingSync = false,
    this.mimeType,
  });

  final String assetFingerprint;
  final String encryptedPath;
  final String thumbnailPath;
  final int byteLength;
  final DateTime createdAt;
  final bool pendingSync;
  final String? mimeType;

  Map<String, Object?> toDatabase() => {
    'asset_fingerprint': assetFingerprint,
    'encrypted_path': encryptedPath,
    'thumbnail_path': thumbnailPath,
    'byte_length': byteLength,
    'mime_type': mimeType,
    'created_at': createdAt.toIso8601String(),
    'pending_sync': pendingSync ? 1 : 0,
  };

  factory ArchiveItem.fromDatabase(Map<String, Object?> row) => ArchiveItem(
    assetFingerprint: row['asset_fingerprint']! as String,
    encryptedPath: row['encrypted_path']! as String,
    thumbnailPath: row['thumbnail_path']! as String,
    byteLength: row['byte_length']! as int,
    mimeType: row['mime_type'] as String?,
    createdAt: DateTime.parse(row['created_at']! as String),
    pendingSync: ((row['pending_sync'] as int?) ?? 0) == 1,
  );
}
