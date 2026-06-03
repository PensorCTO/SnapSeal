import '../models/metered_action_type.dart';
import '../models/quota_state.dart';

/// Reads and records credit-based quota telemetry via Supabase RPCs.
abstract class IMeteringQuotaRepository {
  bool get isConfigured;

  Future<QuotaState> fetchCurrentQuotaStatus();

  Future<QuotaState> recordMeteredConsumption(MeteredActionType actionType);
}
