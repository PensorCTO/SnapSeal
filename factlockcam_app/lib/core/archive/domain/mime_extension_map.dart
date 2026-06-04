/// Shared MIME → file extension mapping for consumer image/video payloads.
String fileExtensionForMimeType(String? mimeType) {
  return switch (mimeType?.trim().toLowerCase()) {
    'image/png' => '.png',
    'image/heic' || 'image/heif' => '.heic',
    'image/gif' => '.gif',
    'video/quicktime' => '.mov',
    'video/webm' => '.webm',
    'video/mp4' || 'video/x-m4v' => '.mp4',
    _ => '.jpg',
  };
}

/// Extension for decrypted exports (share sheet / temp files).
String archiveMediaExtensionForMime(String? mimeType) {
  return fileExtensionForMimeType(mimeType);
}

/// Temp file suffix when generating video thumbnails from bytes.
String videoThumbnailTempExtensionForMime(String? mimeType) {
  return switch (mimeType?.trim().toLowerCase()) {
    'video/quicktime' => '.mov',
    'video/webm' => '.webm',
    'video/3gpp' => '.3gp',
    'video/x-msvideo' => '.avi',
    'video/mpeg' => '.mpeg',
    'video/mp4' || 'video/x-m4v' => '.mp4',
    null || '' => '.mp4',
    _ => '.mp4',
  };
}
