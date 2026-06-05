enum ContentReportReason {
  spam,
  harassment,
  illegal,
  violence,
  sexual,
  other;

  String get rpcValue => name;

  String get label {
    switch (this) {
      case ContentReportReason.spam:
        return 'Spam or misleading';
      case ContentReportReason.harassment:
        return 'Harassment or bullying';
      case ContentReportReason.illegal:
        return 'Illegal activity';
      case ContentReportReason.violence:
        return 'Violence or threats';
      case ContentReportReason.sexual:
        return 'Sexual content';
      case ContentReportReason.other:
        return 'Other concern';
    }
  }
}
