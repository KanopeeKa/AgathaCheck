import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:pet_profile_app/features/auth/auth.dart';
import '../../data/services/revenuecat_service.dart';
import '../../domain/entities/subscription_operation_outcomes.dart';
import '../../domain/entities/subscription_status.dart';

final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService();
});

final subscriptionStatusProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionStatus>((ref) {
      final notifier = SubscriptionNotifier(ref);

      ref.listen<AuthState>(authProvider, (prev, next) {
        final wasLoggedIn = prev?.isLoggedIn ?? false;
        final isLoggedIn = next.isLoggedIn;
        final userId = next.user?.id;

        if (!wasLoggedIn && isLoggedIn && userId != null) {
          notifier.loginUser(userId);
        } else if (wasLoggedIn && !isLoggedIn) {
          notifier.logoutUser();
        }
      });

      return notifier;
    });

class SubscriptionNotifier extends StateNotifier<SubscriptionStatus> {
  final Ref _ref;

  SubscriptionNotifier(this._ref) : super(SubscriptionStatus.free) {
    _init();
  }

  Future<void> _init() async {
    final service = _ref.read(revenueCatServiceProvider);

    if (!service.isInitialized) {
      await service.initialize();
    }

    final authState = _ref.read(authProvider);
    if (authState.isLoggedIn && authState.user?.id != null) {
      await service.login(authState.user!.id);
    }

    await refresh();

    service.addCustomerInfoListener((status) {
      if (mounted) state = status;
    });
  }

  Future<void> refresh() async {
    final previous = state;
    final service = _ref.read(revenueCatServiceProvider);
    final status = await service.getSubscriptionStatus();
    if (!mounted) return;
    if (previous.hasUnlimited && !status.hasUnlimited) {
      return;
    }
    state = status;
  }

  Future<void> loginUser(String userId) async {
    final service = _ref.read(revenueCatServiceProvider);
    await service.login(userId);
    await refresh();
  }

  Future<void> logoutUser() async {
    final service = _ref.read(revenueCatServiceProvider);
    await service.logout();
    if (mounted) state = SubscriptionStatus.free;
  }

  Future<RestoreOutcome> restorePurchases() async {
    final previous = state;
    final service = _ref.read(revenueCatServiceProvider);
    final outcome = await service.restorePurchases();
    if (!mounted) return outcome;
    switch (outcome.kind) {
      case RestoreOutcomeKind.restored:
        state = outcome.status!;
      case RestoreOutcomeKind.nothingToRestore:
        state = SubscriptionStatus.free;
      case RestoreOutcomeKind.failed:
        state = previous;
    }
    return outcome;
  }

  Future<PurchaseOutcome> purchasePackage(Package package) async {
    final service = _ref.read(revenueCatServiceProvider);
    final outcome = await service.purchasePackage(package);
    if (!mounted) return outcome;
    if (outcome.kind == PurchaseOutcomeKind.success) {
      state = outcome.status!;
    } else if (outcome.kind == PurchaseOutcomeKind.pendingUnconfirmed) {
      await refresh();
    }
    return outcome;
  }
}

final hasUnlimitedProvider = Provider<bool>((ref) {
  final status = ref.watch(subscriptionStatusProvider);
  return status.hasUnlimited;
});
