import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/local/vault_database.dart';
import '../../data/services/local_vault_storage.dart';
import '../../data/supabase/auth_repository.dart';
import '../../data/supabase/seal_ledger_repository.dart';
import '../../data/supabase/supabase_client_handle.dart';
import '../crypto/vault_encryption_handler.dart';
import '../../domain/export/certificate_export_service.dart';
import '../../domain/blockchain/chain_notarizer.dart';
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

  getIt.registerLazySingleton<ChainNotarizer>(
    () => AppConfig.usePolygonNotarizer
        ? PolygonChainNotarizer()
        : SimulatedChainNotarizer(getIt<SealLedgerRepository>()),
  );

  getIt.registerLazySingleton<CertificateExportService>(
    CertificateExportService.new,
  );

  getIt.registerLazySingleton<VaultService>(
    () => VaultService(
      database: getIt<VaultDatabase>(),
      storage: getIt<LocalVaultStorage>(),
      secureStorage: getIt<FlutterSecureStorage>(),
      vaultEncryption: getIt<VaultEncryptionHandler>(),
      sealLedgerRepository: getIt<SealLedgerRepository>(),
      chainNotarizer: getIt<ChainNotarizer>(),
      nativeEnclave: getIt<NativeEnclaveChannel>(),
      authRepository: getIt<AuthRepository>(),
    ),
  );
}
