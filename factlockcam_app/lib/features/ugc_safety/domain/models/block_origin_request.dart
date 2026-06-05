class BlockOriginRequest {
  const BlockOriginRequest({
    required this.packageId,
    this.reporterEmail,
  });

  final String packageId;
  final String? reporterEmail;
}

class ContentReportRequest {
  const ContentReportRequest({
    required this.packageId,
    required this.reason,
    this.detail,
    this.reporterEmail,
  });

  final String packageId;
  final String reason;
  final String? detail;
  final String? reporterEmail;
}

class ReporterIdentityStatus {
  const ReporterIdentityStatus({required this.required});

  final bool required;

  static const notRequired = ReporterIdentityStatus(required: false);
}
