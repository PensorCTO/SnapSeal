/// Payment gateway abstraction for Archive subscription upgrades.
///
/// Production will wire StoreKit / Stripe; this release ships a mock only.
abstract class SubscriptionBillingGateway {
  Future<bool> upgradeTier({required String targetTierId});
}
