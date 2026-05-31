/// File extension for decrypted archive media exports (share sheet / temp files).
String archiveMediaExtensionForMime(String? mimeType) {
  final mime = mimeType?.toLowerCase() ?? '';
  if (mime.contains('quicktime')) return '.mov';
  if (mime.contains('webm')) return '.webm';
  if (mime.startsWith('video/')) return '.mp4';
  if (mime.contains('png')) return '.png';
  if (mime.contains('heic')) return '.heic';
  if (mime.contains('gif')) return '.gif';
  return '.jpg';
}
