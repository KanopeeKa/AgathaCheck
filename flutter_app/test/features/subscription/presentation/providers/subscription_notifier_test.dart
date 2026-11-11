import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/subscription/data/services/revenuecat_service.dart';
import 'package:pet_profile_app/features/subscription/domain/entities/subscription_operation_outcomes.dart';
import 'package:pet_profile_app/features/subscription/domain/entities/subscription_status.dart';
import 'package:pet_profile_app/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../helpers/fakes.dart';

class StubRevenueCatService implements RevenueCatService {
  StubRevenueCatService({
    this.restoreOutcome = const RestoreOutcome.failed(),
    this.purchaseOutcome = const PurchaseOutcome.failed(),
    this.subscriptionStatus = SubscriptionStatus.free,
  });

  final RestoreOutcome restoreOutcome;
  final PurchaseOutcome purchaseOutcome;
  SubscriptionStatus subscriptionStatus;

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<RestoreOutcome> restorePurchases() async => restoreOutcome;

  @override
  Future<PurchaseOutcome> purchasePackage(Package package) async =>
      purchaseOutcome;

  @override
  Future<SubscriptionStatus> getSubscriptionStatus() async => subscriptionStatus;

  @override
  Future<List<Offering>> getOfferings() async => [];

  @override
  Future<void> login(String userId) async {}

  @override
  Future<void> logout() async {}

  @override
  void addCustomerInfoListener(void Function(SubscriptionStatus) listener) {}
}

void main() {
  test('failed restore leaves unlimited state unchanged', () async {
    const unlimited = SubscriptionStatus(
      tier: SubscriptionTier.unlimited,
      isActive: true,
    );
    final stub = StubRevenueCatService(
      restoreOutcome: const RestoreOutcome.failed(),
    );

    final container = ProviderContainer(
      overrides: [
        revenueCatServiceProvider.overrideWithValue(stub),
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionStatusProvider.notifier);
    notifier.state = unlimited;

    final outcome = await notifier.restorePurchases();

    expect(outcome.kind, RestoreOutcomeKind.failed);
    expect(container.read(subscriptionStatusProvider).hasUnlimited, isTrue);
  });

  test('nothing to restore clears active entitlement', () async {
    const unlimited = SubscriptionStatus(
      tier: SubscriptionTier.unlimited,
      isActive: true,
    );
    final stub = StubRevenueCatService(
      restoreOutcome: const RestoreOutcome.nothingToRestore(),
    );

    final container = ProviderContainer(
      overrides: [
        revenueCatServiceProvider.overrideWithValue(stub),
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionStatusProvider.notifier);
    notifier.state = unlimited;

    final outcome = await notifier.restorePurchases();

    expect(outcome.kind, RestoreOutcomeKind.nothingToRestore);
    expect(container.read(subscriptionStatusProvider).hasUnlimited, isFalse);
  });

  test('purchase success grants unlimited', () async {
    const unlimited = SubscriptionStatus(
      tier: SubscriptionTier.unlimited,
      isActive: true,
    );
    final stub = StubRevenueCatService(
      purchaseOutcome: PurchaseOutcome.success(unlimited),
    );

    final container = ProviderContainer(
      overrides: [
        revenueCatServiceProvider.overrideWithValue(stub),
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionStatusProvider.notifier);
    final outcome = await notifier.purchasePackage(_monthlyPackage());

    expect(outcome.kind, PurchaseOutcomeKind.success);
    expect(container.read(subscriptionStatusProvider).hasUnlimited, isTrue);
  });

  test('pending purchase does not downgrade confirmed unlimited on stale refresh',
      () async {
    const unlimited = SubscriptionStatus(
      tier: SubscriptionTier.unlimited,
      isActive: true,
    );
    final stub = StubRevenueCatService(
      purchaseOutcome: const PurchaseOutcome.pendingUnconfirmed(),
      subscriptionStatus: SubscriptionStatus.free,
    );

    final container = ProviderContainer(
      overrides: [
        revenueCatServiceProvider.overrideWithValue(stub),
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionStatusProvider.notifier);
    notifier.state = unlimited;

    final outcome = await notifier.purchasePackage(_monthlyPackage());

    expect(outcome.kind, PurchaseOutcomeKind.pendingUnconfirmed);
    expect(container.read(subscriptionStatusProvider).hasUnlimited, isTrue);
  });

  test('restored outcome updates state to unlimited', () async {
    const unlimited = SubscriptionStatus(
      tier: SubscriptionTier.unlimited,
      isActive: true,
    );
    final stub = StubRevenueCatService(
      restoreOutcome: RestoreOutcome.restored(unlimited),
    );

    final container = ProviderContainer(
      overrides: [
        revenueCatServiceProvider.overrideWithValue(stub),
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(subscriptionStatusProvider.notifier);
    final outcome = await notifier.restorePurchases();

    expect(outcome.kind, RestoreOutcomeKind.restored);
    expect(container.read(subscriptionStatusProvider).hasUnlimited, isTrue);
  });
}

Package _monthlyPackage() {
  return Package.fromJson({
    'identifier': '\$rc_monthly',
    'packageType': 'MONTHLY',
    'presentedOfferingContext': {'offeringIdentifier': 'default'},
    'product': {
      'identifier': 'monthly',
      'description': 'Monthly',
      'title': 'Monthly',
      'price': 4.99,
      'priceString': '\$4.99',
      'currencyCode': 'USD',
    },
  });
}
