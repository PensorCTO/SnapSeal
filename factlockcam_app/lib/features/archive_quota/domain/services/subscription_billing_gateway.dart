/// Payment gateway abstraction for Archive subscription upgrades.
///
/// Production will wire StoreKit / Stripe; this release ships a mock only.
abstract class SubscriptionBillingGateway {
  Future<bool> upgradeTier({required String targetTierId});

  /// Restores any previously purchased subscription entitlements.
  ///
  /// Required for App Store Guideline 3.1.1. Production will query StoreKit for
  /// active entitlements; this release returns the current configured state.
  Future<bool> restorePurchases();
}
