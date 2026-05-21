/// Lifecycle states for a vault file mutation recorded in [journal_log].
enum TransactionStatus {
  prepared('prepared'),
  committed('committed'),
  rolledBack('rolled_back');

  const TransactionStatus(this.dbValue);

  final String dbValue;

  static TransactionStatus fromDb(String value) {
    return TransactionStatus.values.firstWhere(
      (s) => s.dbValue == value,
      orElse: () => throw ArgumentError('Unknown transaction_status: $value'),
    );
  }
}
