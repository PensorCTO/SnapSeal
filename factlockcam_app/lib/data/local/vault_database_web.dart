import 'archive_database_web.dart';

export 'archive_database_web.dart';

@Deprecated('Use ArchiveDatabase from archive_database.dart')
typedef VaultDatabase = ArchiveDatabase;

@Deprecated('Use archiveDatabaseProvider')
final vaultDatabaseProvider = archiveDatabaseProvider;
