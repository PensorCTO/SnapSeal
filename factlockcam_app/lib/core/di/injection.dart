import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/local/archive_database.dart';
import '../../data/services/archive_storage.dart';
import '../../data/services/archive_path_resolver.dart';
import '../../data/supabase/auth_repository.dart';
import '../../data/supabase/seal_ledger_repository.dart';
import '../../application/archive/archive_sync_coordinator.dart';
import '../../core/cloud/supabase_archive_service.dart';
import '../../data/supabase/courier_repository.dart';
import '../../features/ugc_safety/data/safety_repository.dart';
import '../../features/archive_quota/data/archive_quota_repository.dart';
import '../../features/archive_quota/data/metering_quota_repository.dart';
import '../../features/archive_quota/data/mock_subscription_billing_gateway.dart';
import '../../features/archive_quota/domain/repositories/i_archive_quota_repository.dart';
import '../../features/archive_quota/domain/repositories/i_metering_quota_repository.dart';
import '../../features/archive_quota/domain/services/archive_quota_service.dart';
import '../../features/archive_quota/domain/services/local_archive_quota_gate.dart';
import '../../features/archive_quota/domain/services/metering_quota_service.dart';
import '../../features/archive_quota/domain/services/subscription_billing_gateway.dart';
import '../../data/supabase/supabase_client_handle.dart';
import '../crypto/archive_encryption_handler.dart';
import '../journal/journal_database_factory.dart';
import '../journal/journal_repository.dart';
import '../journal/transactional_archive_persister.dart';
import '../lock/isolate_lock_coordinator.dart';
import '../lock/lock_journal_sync.dart';
import '../../domain/export/certificate_export_service.dart';
import '../../domain/export/proof_bundle_export_service.dart';
import '../../domain/blockchain/chain_notarizer.dart';
import '../../domain/blockchain/archive_blockchain_handler.dart';
import '../../domain/blockchain/wallet_service.dart';
import '../../domain/services/notarization_monitor_service.dart';
import '../../domain/services/proof_sync_notifier.dart';
import '../../domain/services/archive_service.dart';
import '../ghost_key/app_lock_coordinator.dart';
import '../ghost_key/backup_metadata_store.dart';
import '../ghost_key/factlock_keystore.dart';
import '../ghost_key/key_custody_service.dart';
import '../ghost_key/native_enclave_channel.dart';
import '../ghost_key/wallet_backup_service.dart';
import '../../core/platform/platform_channel_coordinator.dart';
import '../../features/archive/application/proof_courier_service.dart';
import '../../features/archive/data/archive_repository.dart';
import '../../features/archive/domain/repositories/i_archive_repository.dart';
import '../../features/dispatch/camera/secure_comm_camera_pool.dart';
import '../config/app_config.dart';
import 'locator.dart';

var _diConfigured = false;

@visibleForTesting
Future<void> resetDependenciesForTest() async {
  await resetDependenciesAfterStartupFailure();
}

/// Clears a partial GetIt graph when [configureDependencies] fails or times out.
Future<void> resetDependenciesAfterStartupFailure() async {
  if (_diConfigured || getIt.isRegistered<ArchiveDatabase>()) {
    await getIt.reset();
  }
  _diConfigured = false;
}

/// Registers app-wide singletons. Call after [Supabase.initialize] when using defines.
///
/// Uses explicit [GetIt] registration (matches `.cursor/rules/01_flutter_state_architecture.mdc`);
/// `injectable` codegen was not added because `build_runner` failed under this SDK/toolchain.
Future<void> configureDependencies() async {
  if (_diConfigured) {
    return;
  }

  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  getIt.registerLazySingleton<KeyCustodyService>(
    () => KeyCustodyService(secureStorage: getIt<FlutterSecureStorage>()),
  );

  getIt.registerLazySingleton<FactlockKeystore>(FactlockKeystore.new);

  getIt.registerLazySingleton<BackupMetadataStore>(BackupMetadataStore.new);

  getIt.registerLazySingleton<WalletBackupService>(
    () => WalletBackupService(
      keyCustodyService: getIt<KeyCustodyService>(),
      keystore: getIt<FactlockKeystore>(),
      backupMetadataStore: getIt<BackupMetadataStore>(),
    ),
  );

  getIt.registerLazySingleton<AppLockCoordinator>(
    () => AppLockCoordinator(keyCustodyService: getIt<KeyCustodyService>()),
  );

  getIt.registerLazySingleton<SupabaseClientHandle>(SupabaseClientHandle.new);

  getIt.registerLazySingleton<ArchiveDatabase>(ArchiveDatabase.new);
  getIt.registerLazySingleton<IsolateLockCoordinator>(
    IsolateLockCoordinator.new,
  );
  if (!kIsWeb) {
    getIt.registerLazySingleton<LocalArchiveStorage>(
      () => LocalArchiveStorage(lockCoordinator: getIt<IsolateLockCoordinator>()),
    );
  } else {
    getIt.registerLazySingleton<LocalArchiveStorage>(LocalArchiveStorage.new);
  }
  if (!kIsWeb) {
    getIt.registerLazySingleton<JournalDatabaseFactory>(
      JournalDatabaseFactory.new,
    );
    getIt.registerLazySingleton<JournalRepository>(
      () => JournalRepository(getIt<JournalDatabaseFactory>()),
    );
    getIt.registerLazySingleton<TransactionalArchivePersister>(
      () => TransactionalArchivePersister(
        journal: getIt<JournalRepository>(),
        storage: getIt<LocalArchiveStorage>(),
        database: getIt<ArchiveDatabase>(),
        lockCoordinator: getIt<IsolateLockCoordinator>(),
      ),
    );
  }
  getIt.registerLazySingleton<ArchivePathResolver>(
    () => ArchivePathResolver(getIt<LocalArchiveStorage>()),
  );
  if (!kIsWeb) {
    getIt.registerLazySingleton<NativeEnclaveChannel>(
      NativeEnclaveChannel.new,
    );
  }

  getIt.registerLazySingleton<ArchiveEncryptionHandler>(
    DefaultArchiveEncryptionHandler.new,
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<SupabaseClientHandle>()),
  );

  getIt.registerLazySingleton<SealLedgerRepository>(
    () => SealLedgerRepository(getIt<SupabaseClientHandle>()),
  );

  getIt.registerLazySingleton<CourierRepository>(
    () => CourierRepository(getIt<SupabaseClientHandle>()),
  );

  getIt.registerLazySingleton<SafetyRepository>(
    () => SafetyRepository(getIt<SupabaseClientHandle>()),
  );

  getIt.registerLazySingleton<IArchiveQuotaRepository>(
    () => ArchiveQuotaRepository(getIt<SupabaseClientHandle>()),
  );
  getIt.registerLazySingleton<SubscriptionBillingGateway>(
    () => MockSubscriptionBillingGateway(
      repository: getIt<IArchiveQuotaRepository>(),
    ),
  );
  getIt.registerLazySingleton<ArchiveQuotaService>(
    () => ArchiveQuotaService(repository: getIt<IArchiveQuotaRepository>()),
  );
  getIt.registerLazySingleton<LocalArchiveQuotaGate>(
    () => const LocalArchiveQuotaGate(),
  );
  getIt.registerLazySingleton<IMeteringQuotaRepository>(
    () => MeteringQuotaRepository(getIt<SupabaseClientHandle>()),
  );
  getIt.registerLazySingleton<MeteringQuotaService>(
    () => MeteringQuotaService(repository: getIt<IMeteringQuotaRepository>()),
  );

  if (!kIsWeb) {
    getIt.registerLazySingleton<IPlatformChannelCoordinator>(
      PlatformChannelCoordinator.new,
    );
    getIt.registerLazySingleton<ProofCourierService>(
      () => ProofCourierService(
        handle: getIt<SupabaseClientHandle>(),
        channelCoordinator: getIt<IPlatformChannelCoordinator>(),
      ),
    );
    getIt.registerLazySingleton<SupabaseArchiveService>(
      () => SupabaseArchiveService(handle: getIt<SupabaseClientHandle>()),
    );
    getIt.registerLazySingleton<ArchiveSyncCoordinator>(
      () => ArchiveSyncCoordinator(
        sealLedgerRepository: getIt<SealLedgerRepository>(),
        vaultService: getIt<SupabaseArchiveService>(),
        channelCoordinator: getIt<IPlatformChannelCoordinator>(),
      ),
    );
    getIt.registerLazySingleton<ArchiveRepository>(
      () => ArchiveRepository(
        database: getIt<ArchiveDatabase>(),
        storage: getIt<LocalArchiveStorage>(),
      ),
    );
    getIt.registerLazySingleton<IArchiveRepository>(
      () => getIt<ArchiveRepository>(),
    );
  }

  getIt.registerLazySingleton<ChainNotarizer>(
    () => AppConfig.usePolygonNotarizer
        ? PolygonChainNotarizer()
        : SimulatedChainNotarizer(getIt<SealLedgerRepository>()),
  );

  getIt.registerLazySingleton<WalletService>(
    () {
      if (kIsWeb || AppConfig.usePolygonNotarizer) {
        return PolygonWalletService(
          secureStorage: getIt<FlutterSecureStorage>(),
          sealLedgerRepository: getIt<SealLedgerRepository>(),
        );
      }
      return SimulatedWalletService(getIt<NativeEnclaveChannel>());
    },
  );

  getIt.registerLazySingleton<ArchiveBlockchainHandler>(
    () => AppConfig.usePolygonNotarizer
        ? PolygonBlockchainHandler(getIt<SupabaseClientHandle>())
        : SimulatedBlockchainHandler(getIt<SealLedgerRepository>()),
  );

  getIt.registerLazySingleton<ProofSyncNotifier>(ProofSyncNotifier.new);

  getIt.registerLazySingleton<NotarizationMonitorService>(
    () => kIsWeb || !AppConfig.usePolygonNotarizer
        ? SimulatedNotarizationMonitorService()
        : PolygonNotarizationMonitorService(
            handle: getIt<SupabaseClientHandle>(),
            database: getIt<ArchiveDatabase>(),
            proofSyncNotifier: getIt<ProofSyncNotifier>(),
            sealLedgerRepository: getIt<SealLedgerRepository>(),
          ),
  );

  if (!kIsWeb) {
    getIt.registerLazySingleton<CertificateExportService>(
      () => CertificateExportService(
        sealLedgerRepository: getIt<SealLedgerRepository>(),
      ),
    );
  }

  if (!kIsWeb) {
    getIt.registerLazySingleton<ProofBundleExportService>(
      () => ProofBundleExportService(
        sealLedgerRepository: getIt<SealLedgerRepository>(),
      ),
    );
  }

  getIt.registerLazySingleton<SecureCommCameraPool>(SecureCommCameraPool.new);

  getIt.registerLazySingleton<ArchiveService>(
    () => ArchiveService(
      database: getIt<ArchiveDatabase>(),
      storage: getIt<LocalArchiveStorage>(),
      secureStorage: getIt<FlutterSecureStorage>(),
      vaultEncryption: getIt<ArchiveEncryptionHandler>(),
      sealLedgerRepository: getIt<SealLedgerRepository>(),
      chainNotarizer: getIt<ChainNotarizer>(),
      walletService: getIt<WalletService>(),
      blockchainHandler: getIt<ArchiveBlockchainHandler>(),
      proofSyncNotifier: getIt<ProofSyncNotifier>(),
      nativeEnclave: _nativeEnclaveForVaultService(),
      authRepository: getIt<AuthRepository>(),
      proofCourierService: kIsWeb ? null : getIt<ProofCourierService>(),
      pathResolver: getIt<ArchivePathResolver>(),
      vaultSyncCoordinator: kIsWeb ? null : getIt<ArchiveSyncCoordinator>(),
      transactionalPersister: kIsWeb
          ? null
          : getIt<TransactionalArchivePersister>(),
      keyCustodyService: getIt<KeyCustodyService>(),
      isolateLockCoordinator: getIt<IsolateLockCoordinator>(),
      journalRepository: getIt<JournalRepository>(),
      localQuotaGate: getIt<LocalArchiveQuotaGate>(),
      archiveQuotaService: getIt<ArchiveQuotaService>(),
    ),
  );
  // Eager-open SQLite before hub/dashboard and capture can race on first connect.
  if (!kIsWeb) {
    await getIt<ArchiveDatabase>().ensureOpen();
    final journal = getIt<JournalRepository>();
    await journal.open();
    syncLocksFromPreparedJournal(
      journal: journal,
      coordinator: getIt<IsolateLockCoordinator>(),
    );
  }

  _diConfigured = true;
}

/// Web uses a throw-on-call stub; native uses the GetIt singleton.
NativeEnclaveChannel _nativeEnclaveForVaultService() {
  if (kIsWeb) {
    return NativeEnclaveChannel();
  }
  return getIt<NativeEnclaveChannel>();
}
