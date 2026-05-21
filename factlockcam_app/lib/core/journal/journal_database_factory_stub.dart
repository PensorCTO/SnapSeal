/// Web / non-IO targets: journal WAL engine is mobile/desktop only.
class JournalDatabaseFactory {
  JournalDatabaseFactory({String? embeddedPath});

  Future<void> open() async {}

  void dispose() {}

  bool get isAvailable => false;

  Never get database => throw UnsupportedError(
    'JournalDatabaseFactory is unavailable on this platform.',
  );

  String readJournalMode() => throw UnsupportedError(
    'JournalDatabaseFactory is unavailable on this platform.',
  );
}
