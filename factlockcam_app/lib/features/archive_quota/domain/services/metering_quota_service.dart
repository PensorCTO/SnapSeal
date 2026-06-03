import '../models/metered_action_type.dart';
import '../models/quota_state.dart';
import '../repositories/i_metering_quota_repository.dart';

/// Business rules for credit-based pro-proof and verification credit metering.
class MeteringQuotaService {
  MeteringQuotaService({required IMeteringQuotaRepository repository})
      : _repository = repository;

  final IMeteringQuotaRepository _repository;

  bool get isConfigured => _repository.isConfigured;

  Future<QuotaState> fetchStatus() => _repository.fetchCurrentQuotaStatus();

  Future<QuotaState> recordConsumption(MeteredActionType type) =>
      _repository.recordMeteredConsumption(type);

  QuotaState optimisticDebit(QuotaState current, MeteredActionType type) {
    return switch (type) {
      MeteredActionType.proProof => current.copyWith(
          proProofsRemaining: (current.proProofsRemaining - 1).clamp(0, 999999),
        ),
      MeteredActionType.verificationCredit => current.copyWith(
          egressCreditsBalance:
              (current.egressCreditsBalance - 1).clamp(0, 999999),
        ),
    };
  }

  bool canDebit(QuotaState current, MeteredActionType type) {
    return switch (type) {
      MeteredActionType.proProof => current.hasProProofsRemaining,
      MeteredActionType.verificationCredit => current.hasVerificationCredits,
    };
  }
}
