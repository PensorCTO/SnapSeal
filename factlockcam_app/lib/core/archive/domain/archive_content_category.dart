/// Content category for sealed archive payloads (consumer: image + video only).
enum ArchiveContentCategory {
  image,
  video,
  audio,
  document,
  archive,
  binary,
}

/// Maps a MIME type string to [ArchiveContentCategory].
ArchiveContentCategory categoryFromMime(String? mimeType) {
  final normalized = mimeType?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty) {
    return ArchiveContentCategory.binary;
  }

  if (normalized == 'picture' || normalized == 'photo') {
    return ArchiveContentCategory.image;
  }
  if (normalized == 'video') {
    return ArchiveContentCategory.video;
  }

  if (normalized.startsWith('image/')) {
    return ArchiveContentCategory.image;
  }
  if (normalized.startsWith('video/')) {
    return ArchiveContentCategory.video;
  }
  if (normalized.startsWith('audio/')) {
    return ArchiveContentCategory.audio;
  }
  if (normalized == 'application/pdf' ||
      normalized.startsWith('text/') ||
      (normalized.startsWith('application/') &&
          !normalized.contains('octet-stream') &&
          !normalized.contains('zip'))) {
    return ArchiveContentCategory.document;
  }
  if (normalized.contains('zip') ||
      normalized.contains('tar') ||
      normalized.contains('gzip')) {
    return ArchiveContentCategory.archive;
  }

  return ArchiveContentCategory.binary;
}

extension ArchiveContentCategoryX on ArchiveContentCategory {
  /// SQL / RPC `content_category` column value.
  String get rpcValue => name;

  /// Consumer FactLockCam (picture + video capture) supports only these categories.
  bool get isConsumerSupported =>
      this == ArchiveContentCategory.image ||
      this == ArchiveContentCategory.video;

  void assertConsumerSupported({required bool arbitraryFileSealEnabled}) {
    if (arbitraryFileSealEnabled || isConsumerSupported) {
      return;
    }
    assert(
      false,
      'Consumer build supports image/video payloads only ($this). '
      'Enable ENABLE_ARBITRARY_FILE_SEAL for institution-grade ingress.',
    );
  }
}
