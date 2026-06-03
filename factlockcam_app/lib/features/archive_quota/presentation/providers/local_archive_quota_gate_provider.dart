import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/local_archive_quota_gate.dart';

final localArchiveQuotaGateProvider = Provider<LocalArchiveQuotaGate>(
  (ref) => const LocalArchiveQuotaGate(),
);
