import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/vault_service.dart';

export '../../data/local/vault_database.dart' show vaultDatabaseProvider;
export '../../data/services/local_vault_storage.dart'
    show localVaultStorageProvider;
export '../../domain/export/certificate_export_service.dart'
    show certificateExportServiceProvider;
export '../../domain/export/proof_bundle_export_service.dart'
    show proofBundleExportServiceProvider;
export '../../domain/services/vault_service.dart' show vaultServiceProvider;

/// ProofLock-facing bridge for archive interactions.
///
/// The current implementation uses [VaultService] as the owner-side ProofLock
/// surface until a dedicated ProofLock service is introduced.
final proofLockServiceProvider = Provider<VaultService>(
  (ref) => ref.watch(vaultServiceProvider),
);
