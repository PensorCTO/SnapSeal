/// No-op on web; courier unlock does not use the WAL journal engine.
Future<void> runBootRecoveryBeforeUi() async {}
