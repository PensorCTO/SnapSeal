/// Subscription tier limits for the cloud Archive.
class ArchiveTier {
  const ArchiveTier({
    required this.tierId,
    required this.displayName,
    required this.storageLimitBytes,
    required this.egressLimitBytes,
    required this.monthlyPriceCents,
    this.maxSingleCaptureBytes,
  });

  final String tierId;
  final String displayName;
  final int storageLimitBytes;
  final int egressLimitBytes;
  final int monthlyPriceCents;

  /// Per-capture cap (e.g. 50 MB on free tier). Null means tier storage cap only.
  final int? maxSingleCaptureBytes;

  factory ArchiveTier.fromJson(Map<String, dynamic> json) {
    final rawMax = json['max_single_capture_bytes'];
    return ArchiveTier(
      tierId: json['tier_id'] as String,
      displayName: json['display_name'] as String,
      storageLimitBytes: parseQuotaInt(json['storage_limit_bytes']),
      egressLimitBytes: parseQuotaInt(json['egress_limit_bytes']),
      monthlyPriceCents: parseQuotaInt(json['monthly_price_cents']),
      maxSingleCaptureBytes: rawMax == null
          ? null
          : parseQuotaInt(rawMax),
    );
  }
}

int parseQuotaInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.parse(value.toString());
}
