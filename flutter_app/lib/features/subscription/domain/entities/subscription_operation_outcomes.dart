import 'subscription_status.dart';

/// Result of a store purchase attempt (not thrown; mapped from RevenueCat).
enum PurchaseOutcomeKind { success, cancelled, failed, pendingUnconfirmed }

class PurchaseOutcome {
  const PurchaseOutcome._(this.kind, this.status);

  final PurchaseOutcomeKind kind;

  /// Set only when [kind] is [PurchaseOutcomeKind.success].
  final SubscriptionStatus? status;

  const PurchaseOutcome.success(SubscriptionStatus status)
    : this._(PurchaseOutcomeKind.success, status);

  const PurchaseOutcome.cancelled() : this._(PurchaseOutcomeKind.cancelled, null);

  const PurchaseOutcome.failed() : this._(PurchaseOutcomeKind.failed, null);

  const PurchaseOutcome.pendingUnconfirmed()
    : this._(PurchaseOutcomeKind.pendingUnconfirmed, null);
}

enum RestoreOutcomeKind { restored, nothingToRestore, failed }

class RestoreOutcome {
  const RestoreOutcome._(this.kind, this.status);

  final RestoreOutcomeKind kind;

  /// Set only when [kind] is [RestoreOutcomeKind.restored].
  final SubscriptionStatus? status;

  const RestoreOutcome.restored(SubscriptionStatus status)
    : this._(RestoreOutcomeKind.restored, status);

  const RestoreOutcome.nothingToRestore()
    : this._(RestoreOutcomeKind.nothingToRestore, null);

  const RestoreOutcome.failed() : this._(RestoreOutcomeKind.failed, null);
}
