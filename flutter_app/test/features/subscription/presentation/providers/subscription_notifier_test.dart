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
  });

  final RestoreOutcome restoreOutcome;
  final PurchaseOutcome purchaseOutcome;

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
  Future<SubscriptionStatus> getSubscriptionStatus() async =>
      SubscriptionStatus.free;

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
