/// Offline fallback limits when quota RPC is unavailable (matches free tier migration).
class ArchiveTierDefaults {
  ArchiveTierDefaults._();

  static const String freeTierId = 'free';

  static const int freeStorageLimitBytes = 52428800; // 50 MB
  static const int freeEgressLimitBytes = 3221225472; // 3 GB
  static const int freeMaxSingleCaptureBytes = 52428800; // 50 MB
}
