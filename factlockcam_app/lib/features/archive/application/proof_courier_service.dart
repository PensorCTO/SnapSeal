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

  /// JIT upload: isolate read + background-scoped storage upload.
  Future<void> uploadEncryptedCourierBlob({
    required String storagePath,
    required Uint8List encryptedBytes,
  }) async {
    final client = _requiredClient();
    await _channelCoordinator.executeWithBackgroundScope(() async {
      final payload = await Isolate.run(
        () => _copyBytesInIsolate(encryptedBytes),
      );
      await client.storage.from('courier-blobs').uploadBinary(
            storagePath,
            payload,
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
    return _channelCoordinator.executeWithBackgroundScope(() async {
      final payload = await Isolate.run(
        () => _readEncryptedFileInIsolate(localEncryptedFile.path),
      );
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

Uint8List _copyBytesInIsolate(Uint8List encryptedBytes) {
  return Uint8List.fromList(encryptedBytes);
}

Uint8List _readEncryptedFileInIsolate(String path) {
  return File(path).readAsBytesSync();
}
