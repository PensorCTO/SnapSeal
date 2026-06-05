import 'archive_service_web.dart';

export 'archive_service_web.dart';

@Deprecated('Use ArchiveService from archive_service.dart')
typedef VaultService = ArchiveService;

@Deprecated('Use archiveServiceProvider')
final vaultServiceProvider = archiveServiceProvider;
