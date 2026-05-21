import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/local/vault_database.dart';
import '../../data/services/local_vault_storage.dart';
import '../../data/services/vault_path_resolver.dart';
import '../../data/supabase/auth_repository.dart';
import '../../data/supabase/seal_ledger_repository.dart';
import '../../data/supabase/courier_repository.dart';
import '../../data/supabase/supabase_client_handle.dart';
import '../crypto/vault_encryption_handler.dart';
import '../journal/journal_database_factory.dart';
import '../journal/journal_repository.dart';
import '../journal/transactional_vault_persister.dart';
import '../../domain/export/certificate_export_service.dart';
import '../../domain/blockchain/chain_notarizer.dart';
import '../../domain/blockchain/vault_blockchain_handler.dart';
import '../../domain/blockchain/wallet_service.dart';
import '../../domain/services/notarization_monitor_service.dart';
import '../../domain/services/proof_sync_notifier.dart';
import '../../domain/services/vault_service.dart';
import '../ghost_key/native_enclave_channel.dart';
import '../config/app_config.dart';
import 'locator.dart';

var _diConfigured = false;

/// Registers app-wide singletons. Call after [Supabase.initialize] when using defines.
///
/// Uses explicit [GetIt] registration (matches `.cursor/rules/01_flutter_state_architecture.mdc`);
/// `injectable` codegen was not added because `build_runner` failed under this SDK/toolchain.
Future<void> configureDependencies() async {
  if (_diConfigured) {
    return;
  }
  _diConfigured = true;

  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  getIt.registerLazySingleton<SupabaseClientHandle>(SupabaseClientHandle.new);

  getIt.registerLazySingleton<VaultDatabase>(VaultDatabase.new);
  getIt.registerLazySingleton<LocalVaultStorage>(LocalVaultStorage.new);
  if (!kIsWeb) {
    getIt.registerLazySingleton<JournalDatabaseFactory>(
      JournalDatabaseFactory.new,
    );
    getIt.registerLazySingleton<JournalRepository>(
      () => JournalRepository(getIt<JournalDatabaseFactory>()),
    );
    getIt.registerLazySingleton<TransactionalVaultPersister>(
      () => TransactionalVaultPersister(
        journal: getIt<JournalRepository>(),
        storage: getIt<LocalVaultStorage>(),
        database: getIt<VaultDatabase>(),
      ),
    );
  }
  getIt.registerLazySingleton<VaultPathResolver>(
    () => VaultPathResolver(getIt<LocalVaultStorage>()),
  );
  getIt.registerLazySingleton<NativeEnclaveChannel>(NativeEnclaveChannel.new);

  getIt.registerLazySingleton<VaultEncryptionHandler>(
    DefaultVaultEncryptionHandler.new,
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

  getIt.registerLazySingleton<ChainNotarizer>(
    () => AppConfig.usePolygonNotarizer
        ? PolygonChainNotarizer()
        : SimulatedChainNotarizer(getIt<SealLedgerRepository>()),
  );

  getIt.registerLazySingleton<WalletService>(
    () => AppConfig.usePolygonNotarizer
        ? PolygonWalletService(
            secureStorage: getIt<FlutterSecureStorage>(),
            sealLedgerRepository: getIt<SealLedgerRepository>(),
          )
        : SimulatedWalletService(getIt<NativeEnclaveChannel>()),
  );

  getIt.registerLazySingleton<VaultBlockchainHandler>(
    () => AppConfig.usePolygonNotarizer
        ? PolygonBlockchainHandler(getIt<SupabaseClientHandle>())
        : SimulatedBlockchainHandler(getIt<SealLedgerRepository>()),
  );

  getIt.registerLazySingleton<ProofSyncNotifier>(ProofSyncNotifier.new);

  getIt.registerLazySingleton<NotarizationMonitorService>(
    () => AppConfig.usePolygonNotarizer
        ? PolygonNotarizationMonitorService(
            handle: getIt<SupabaseClientHandle>(),
            database: getIt<VaultDatabase>(),
            proofSyncNotifier: getIt<ProofSyncNotifier>(),
            sealLedgerRepository: getIt<SealLedgerRepository>(),
          )
        : SimulatedNotarizationMonitorService(),
  );

  getIt.registerLazySingleton<CertificateExportService>(
    () => CertificateExportService(
      sealLedgerRepository: getIt<SealLedgerRepository>(),
    ),
  );

  getIt.registerLazySingleton<VaultService>(
    () => VaultService(
      database: getIt<VaultDatabase>(),
      storage: getIt<LocalVaultStorage>(),
      secureStorage: getIt<FlutterSecureStorage>(),
      vaultEncryption: getIt<VaultEncryptionHandler>(),
      sealLedgerRepository: getIt<SealLedgerRepository>(),
      chainNotarizer: getIt<ChainNotarizer>(),
      walletService: getIt<WalletService>(),
      blockchainHandler: getIt<VaultBlockchainHandler>(),
      proofSyncNotifier: getIt<ProofSyncNotifier>(),
      nativeEnclave: getIt<NativeEnclaveChannel>(),
      authRepository: getIt<AuthRepository>(),
      pathResolver: getIt<VaultPathResolver>(),
      transactionalPersister: kIsWeb
          ? null
          : getIt<TransactionalVaultPersister>(),
    ),
  );

  // Eager-open SQLite before hub/dashboard and capture can race on first connect.
  if (!kIsWeb) {
    await getIt<VaultDatabase>().ensureOpen();
    await getIt<JournalRepository>().open();
  }
}
