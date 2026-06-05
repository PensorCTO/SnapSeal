import 'archive_database_io.dart';

export 'archive_database_io.dart';

@Deprecated('Use ArchiveDatabase from archive_database.dart')
typedef VaultDatabase = ArchiveDatabase;

@Deprecated('Use archiveDatabaseProvider')
final vaultDatabaseProvider = archiveDatabaseProvider;
