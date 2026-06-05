import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/exceptions.dart';
import '../../data/supabase/supabase_client_handle.dart';

/// Uploads client-side encrypted ciphertext to the private cloud vault bucket.
///
/// Encryption must occur before calling [uploadEncryptedAsset] — see
/// [VaultSyncCoordinator.syncAfterNotarization].
class SupabaseArchiveService {
  SupabaseArchiveService({required SupabaseClientHandle handle})
      : _handle = handle;

  static const String bucketName = 'factlock_vault';
  static const int maxUploadBytes = 50 * 1024 * 1024;

  final SupabaseClientHandle _handle;

  /// Binary PUT to `factlock_vault` and courier_packages metadata update.
  ///
  /// Throws [QuotaExceededException] when ciphertext exceeds the 50MB limit.
  Future<String> uploadEncryptedAsset({
    required Uint8List encryptedBytes,
    required String packageId,
    required String storagePath,
    required int plaintextFileSizeBytes,
  }) async {
    final client = _requiredClient();
    final userId = client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Authenticated user required for cloud archive upload.');
    }

    if (encryptedBytes.length > maxUploadBytes) {
      throw QuotaExceededException(
        'Encrypted payload exceeds 50MB limit.',
      );
    }

    if (plaintextFileSizeBytes > maxUploadBytes) {
      throw QuotaExceededException(
        'Asset exceeds 50MB limit. Compress before sealing.',
      );
    }

    await client.storage.from(bucketName).uploadBinary(
          storagePath,
          encryptedBytes,
          fileOptions: const FileOptions(
            contentType: 'application/octet-stream',
            cacheControl: '3600',
            upsert: false,
          ),
        );

    await client.from('courier_packages').update(<String, dynamic>{
      'storage_bucket': bucketName,
      'storage_path': storagePath,
      'file_size_bytes': plaintextFileSizeBytes,
    }).eq('package_id', packageId);

    return storagePath;
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
