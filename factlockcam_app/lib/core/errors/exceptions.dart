/// Thrown when an upload exceeds tier or client-side size limits.
class QuotaExceededException implements Exception {
  QuotaExceededException(this.message);

  final String message;

  @override
  String toString() => 'QuotaExceededException: $message';
}
