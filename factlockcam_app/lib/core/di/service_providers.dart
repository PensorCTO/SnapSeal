import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ghost_key/app_lock_coordinator.dart';
import '../ghost_key/backup_metadata_store.dart';
import '../ghost_key/wallet_backup_service.dart';
import '../platform/platform_channel_coordinator.dart';
import '../../data/supabase/courier_repository.dart';
import '../../domain/services/vault_service.dart';
import 'locator.dart';

export '../../data/local/vault_database.dart' show vaultDatabaseProvider;
export '../../data/services/local_vault_storage.dart'
    show localVaultStorageProvider;
export '../../domain/export/certificate_export_service.dart'
    show certificateExportServiceProvider;
export '../../domain/export/proof_bundle_export_service.dart'
    show proofBundleExportServiceProvider;
export '../../features/archive/presentation/providers/send_proof_provider.dart'
    show sendProofProvider;
export '../../domain/services/vault_service.dart' show vaultServiceProvider;
export '../../features/archive/application/proof_courier_service.dart'
    show proofCourierServiceProvider;
export '../../features/archive/data/archive_repository.dart'
    show archiveRepositoryProvider, archiveAssetManifestProvider;
export '../../features/identity/presentation/providers/current_profile_provider.dart'
    show currentProfileProvider;
export '../../ui/controllers/key_custody_provider.dart' show keyCustodyProvider;

/// ProofLock-facing bridge for archive interactions.
///
/// The current implementation uses [VaultService] as the owner-side ProofLock
/// surface until a dedicated ProofLock service is introduced.
final proofLockServiceProvider = Provider<VaultService>(
  (ref) => ref.watch(vaultServiceProvider),
);

final walletBackupServiceProvider = Provider<WalletBackupService>(
  (ref) => getIt<WalletBackupService>(),
);

final backupMetadataStoreProvider = Provider<BackupMetadataStore>(
  (ref) => getIt<BackupMetadataStore>(),
);

final appLockCoordinatorProvider = Provider<AppLockCoordinator>(
  (ref) => getIt<AppLockCoordinator>(),
);

final platformChannelCoordinatorProvider =
    Provider<IPlatformChannelCoordinator>(
  (ref) => getIt<IPlatformChannelCoordinator>(),
);

final courierRepositoryProvider = Provider<CourierRepository>(
  (ref) => getIt<CourierRepository>(),
);
