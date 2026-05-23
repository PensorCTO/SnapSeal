import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/locator.dart';
import '../../../core/platform/platform_channel_coordinator.dart';
import '../../../data/supabase/supabase_client_handle.dart';

final proofCourierServiceProvider = Provider<ProofCourierService>(
  (ref) => getIt<ProofCourierService>(),
);

class ProofCourierService {
  ProofCourierService({
    required SupabaseClientHandle handle,
    required IPlatformChannelCoordinator channelCoordinator,
  })  : _handle = handle,
        _channelCoordinator = channelCoordinator;

  final SupabaseClientHandle _handle;
  final IPlatformChannelCoordinator _channelCoordinator;

  /// JIT upload with background task scope for iOS upload continuity.
  ///
  /// File bytes are already loaded on the caller isolate; do not nest
  /// [Isolate.run] inside the upload callback — closures that share scope
  /// with [SupabaseClient] are not isolate-sendable.
  Future<void> uploadEncryptedCourierBlob({
    required String storagePath,
    required Uint8List encryptedBytes,
  }) async {
    await _channelCoordinator.executeWithBackgroundScope(() async {
      final client = _requiredClient();
      await client.storage.from('courier-blobs').uploadBinary(
            storagePath,
            encryptedBytes,
            fileOptions: const FileOptions(
              contentType: 'application/octet-stream',
              upsert: true,
            ),
          );
    });
  }

  Future<String> executeTransientLinkGeneration(
    File localEncryptedFile,
    String assetHash,
  ) async {
    final filePath = localEncryptedFile.path;
    final payload = await Isolate.run(
      () => _readEncryptedFileInIsolate(filePath),
    );

    return _channelCoordinator.executeWithBackgroundScope(() async {
      final storageDestination = 'courier_drops/$assetHash.plock';
      final client = _requiredClient();
      await client.storage.from('courier-blobs').uploadBinary(
            storageDestination,
            payload,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );
      return client.storage
          .from('courier-blobs')
          .createSignedUrl(storageDestination, 86400);
    });
  }

  SupabaseClient _requiredClient() {
    final client = _handle.client;
    if (client == null) {
      throw StateError(
        'Supabase is not configured. Run with --dart-define SUPABASE_URL=... '
        'and --dart-define SUPABASE_ANON_KEY=...',
      );
    }
    return client;
  }
}

Uint8List _readEncryptedFileInIsolate(String path) {
  return File(path).readAsBytesSync();
}
