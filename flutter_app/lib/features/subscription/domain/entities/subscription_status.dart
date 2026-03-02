enum SubscriptionTier { free, unlimited }

class SubscriptionStatus {
  final SubscriptionTier tier;
  final bool isActive;
  final DateTime? expirationDate;
  final String? managementUrl;
  final String? productIdentifier;

  const SubscriptionStatus({
    this.tier = SubscriptionTier.free,
    this.isActive = false,
    this.expirationDate,
    this.managementUrl,
    this.productIdentifier,
  });

  bool get hasUnlimited => tier == SubscriptionTier.unlimited && isActive;

  static const free = SubscriptionStatus();
}
