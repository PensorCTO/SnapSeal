import 'dart:async';
import 'dart:isolate';

/// Live lock state mirrored from journal prepare/commit and worker isolates.
enum LockState { processing, idle }

/// Notification that an asset fingerprint entered or left an advisory lock.
class IsolateLockEvent {
  const IsolateLockEvent(this.fileId, this.state);

  final String fileId;
  final LockState state;
}

/// Central coordinator on the UI isolate: synchronous cache + broadcast stream.
///
/// Background workers send `{'fileId': String, 'isProcessing': bool}` maps to
/// [notifyPort]. Main-thread persistence calls [lock]/[unlock] directly.
class IsolateLockCoordinator {
  IsolateLockCoordinator() {
    _receivePort.listen(_handleMessage);
  }

  final _receivePort = ReceivePort();
  final _controller = StreamController<IsolateLockEvent>.broadcast();
  final Set<String> _activeLocks = {};

  Stream<IsolateLockEvent> get lockStream => _controller.stream;

  /// Port passed into [Isolate.spawn] / worker entry points for remote updates.
  SendPort get notifyPort => _receivePort.sendPort;

  bool isFileLocked(String fileId) => _activeLocks.contains(fileId);

  Set<String> snapshotActiveLocks() => Set<String>.unmodifiable(_activeLocks);

  void lock(String fileId) => _apply(fileId, processing: true);

  void unlock(String fileId) => _apply(fileId, processing: false);

  void _handleMessage(Object? message) {
    if (message is! Map) {
      return;
    }
    final fileId = message['fileId'];
    final isProcessing = message['isProcessing'];
    if (fileId is! String || fileId.isEmpty) {
      return;
    }
    if (isProcessing is! bool) {
      return;
    }
    _apply(fileId, processing: isProcessing);
  }

  void _apply(String fileId, {required bool processing}) {
    if (processing) {
      if (_activeLocks.add(fileId)) {
        _controller.add(IsolateLockEvent(fileId, LockState.processing));
      }
    } else {
      if (_activeLocks.remove(fileId)) {
        _controller.add(IsolateLockEvent(fileId, LockState.idle));
      }
    }
  }

  void dispose() {
    _receivePort.close();
    unawaited(_controller.close());
    _activeLocks.clear();
  }
}

/// Thrown when UI or domain code attempts to read bytes for a locked asset.
class AssetFileLockedException implements Exception {
  AssetFileLockedException(this.assetFingerprint);

  final String assetFingerprint;

  @override
  String toString() =>
      'AssetFileLockedException(assetFingerprint: $assetFingerprint)';
}
