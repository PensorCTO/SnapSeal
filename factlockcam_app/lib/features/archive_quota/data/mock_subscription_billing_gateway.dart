import '../domain/repositories/i_archive_quota_repository.dart';
import '../domain/services/subscription_billing_gateway.dart';

/// Mock billing gateway — simulates a successful tier upgrade without IAP.
class MockSubscriptionBillingGateway implements SubscriptionBillingGateway {
  MockSubscriptionBillingGateway({required IArchiveQuotaRepository repository})
      : _repository = repository;

  final IArchiveQuotaRepository _repository;

  @override
  Future<bool> upgradeTier({required String targetTierId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!_repository.isConfigured) {
      return false;
    }
    await _repository.setTier(targetTierId);
    return true;
  }
}
