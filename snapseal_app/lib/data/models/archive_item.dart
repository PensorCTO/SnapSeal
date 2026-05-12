/// Sentinel for [ArchiveItem.copyWith]: distinguishes "omit argument" from "set null".
class _ArchiveCopyUnset {
  const _ArchiveCopyUnset();
}

const _archiveCopyUnset = _ArchiveCopyUnset();

class ArchiveItem {
  const ArchiveItem({
    required this.assetFingerprint,
    required this.encryptedPath,
    required this.thumbnailPath,
    required this.byteLength,
    required this.createdAt,
    this.pendingSync = false,
    this.mimeType,
    this.title,
    this.description,
    this.syncAttemptCount = 0,
    this.lastSyncAttemptAt,
    this.nextRetryAt,
  });

  final String assetFingerprint;
  final String encryptedPath;
  final String thumbnailPath;
  final int byteLength;
  final DateTime createdAt;
  final bool pendingSync;
  final String? mimeType;
  final String? title;
  final String? description;
  final int syncAttemptCount;
  final DateTime? lastSyncAttemptAt;
  final DateTime? nextRetryAt;

  ArchiveItem copyWith({
    String? assetFingerprint,
    String? encryptedPath,
    String? thumbnailPath,
    int? byteLength,
    DateTime? createdAt,
    bool? pendingSync,
    Object? mimeType = _archiveCopyUnset,
    Object? title = _archiveCopyUnset,
    Object? description = _archiveCopyUnset,
    int? syncAttemptCount,
    Object? lastSyncAttemptAt = _archiveCopyUnset,
    Object? nextRetryAt = _archiveCopyUnset,
  }) => ArchiveItem(
    assetFingerprint: assetFingerprint ?? this.assetFingerprint,
    encryptedPath: encryptedPath ?? this.encryptedPath,
    thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    byteLength: byteLength ?? this.byteLength,
    createdAt: createdAt ?? this.createdAt,
    pendingSync: pendingSync ?? this.pendingSync,
    mimeType: identical(mimeType, _archiveCopyUnset)
        ? this.mimeType
        : mimeType as String?,
    title: identical(title, _archiveCopyUnset)
        ? this.title
        : title as String?,
    description: identical(description, _archiveCopyUnset)
        ? this.description
        : description as String?,
    syncAttemptCount: syncAttemptCount ?? this.syncAttemptCount,
    lastSyncAttemptAt: identical(lastSyncAttemptAt, _archiveCopyUnset)
        ? this.lastSyncAttemptAt
        : lastSyncAttemptAt as DateTime?,
    nextRetryAt: identical(nextRetryAt, _archiveCopyUnset)
        ? this.nextRetryAt
        : nextRetryAt as DateTime?,
  );

  Map<String, Object?> toDatabase() => {
    'asset_fingerprint': assetFingerprint,
    'encrypted_path': encryptedPath,
    'thumbnail_path': thumbnailPath,
    'byte_length': byteLength,
    'mime_type': mimeType,
    'created_at': createdAt.toIso8601String(),
    'pending_sync': pendingSync ? 1 : 0,
    'title': title,
    'description': description,
    'sync_attempt_count': syncAttemptCount,
    'last_sync_attempt_at': lastSyncAttemptAt?.toIso8601String(),
    'next_retry_at': nextRetryAt?.toIso8601String(),
  };

  factory ArchiveItem.fromDatabase(Map<String, Object?> row) => ArchiveItem(
    assetFingerprint: row['asset_fingerprint']! as String,
    encryptedPath: row['encrypted_path']! as String,
    thumbnailPath: row['thumbnail_path']! as String,
    byteLength: row['byte_length']! as int,
    mimeType: row['mime_type'] as String?,
    createdAt: DateTime.parse(row['created_at']! as String),
    pendingSync: ((row['pending_sync'] as int?) ?? 0) == 1,
    title: row['title'] as String?,
    description: row['description'] as String?,
    syncAttemptCount: (row['sync_attempt_count'] as int?) ?? 0,
    lastSyncAttemptAt: (row['last_sync_attempt_at'] as String?) == null
        ? null
        : DateTime.parse(row['last_sync_attempt_at']! as String),
    nextRetryAt: (row['next_retry_at'] as String?) == null
        ? null
        : DateTime.parse(row['next_retry_at']! as String),
  );
}
