import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

abstract class IPlatformChannelCoordinator {
  Future<T> executeWithBackgroundScope<T>(
    Future<T> Function() criticalUploadTask,
  );

  Future<Uint8List?> pickEncryptedBackupBytes();

  Future<Uint8List?> pickFactlockBackupBytes();
}

class PlatformChannelCoordinator implements IPlatformChannelCoordinator {
  PlatformChannelCoordinator({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.factlockcam.app/platform');

  final MethodChannel _channel;

  @override
  Future<T> executeWithBackgroundScope<T>(
    Future<T> Function() criticalUploadTask,
  ) async {
    if (kIsWeb) {
      return criticalUploadTask();
    }

    int? taskId;
    try {
      taskId = await _channel.invokeMethod<int>('beginBackgroundTask');
      return await criticalUploadTask();
    } finally {
      if (taskId != null) {
        await _channel.invokeMethod<void>('endBackgroundTask', taskId);
      }
    }
  }

  @override
  Future<Uint8List?> pickEncryptedBackupBytes() async {
    if (kIsWeb) {
      return null;
    }
    final bytes = await _channel.invokeMethod<Uint8List>(
      'pickEncryptedBackupBytes',
    );
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    return bytes;
  }

  @override
  Future<Uint8List?> pickFactlockBackupBytes() async {
    if (kIsWeb) {
      return null;
    }
    final bytes = await _channel.invokeMethod<Uint8List>(
      'pickFactlockBackupBytes',
    );
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    return bytes;
  }
}
