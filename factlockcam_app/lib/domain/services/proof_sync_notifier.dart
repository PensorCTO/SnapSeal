import 'dart:async';

/// Broadcasts when a remote proof row is finalized and local pending_sync clears.
class ProofSyncNotifier {
  final _controller = StreamController<String>.broadcast();

  Stream<String> get onAssetSynced => _controller.stream;

  void notifyAssetSynced(String assetFingerprint) {
    final normalized = assetFingerprint.trim();
    if (normalized.isEmpty || _controller.isClosed) {
      return;
    }
    _controller.add(normalized);
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
