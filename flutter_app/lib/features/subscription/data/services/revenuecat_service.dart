import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../domain/entities/subscription_operation_outcomes.dart';
import '../../domain/entities/subscription_status.dart';

class RevenueCatConfig {
  // Provide at build time with:
  //   flutter build web --dart-define=REVENUECAT_PUBLIC_API_KEY=<key>
  // Falls back to the existing public test key so local/dev builds keep working
  // without extra flags. Do not commit a real production key in source.
  static const String publicApiKey = String.fromEnvironment(
    'REVENUECAT_PUBLIC_API_KEY',
    defaultValue: 'test_mChvbdszQBlZxZxjoINftJrAbTx',
  );

  // NOTE: this must match the entitlement identifier configured in the
  // RevenueCat dashboard exactly — including the historical "Agatah" spelling.
  // Override per environment with --dart-define=REVENUECAT_ENTITLEMENT_ID=...
  static const String entitlementId = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT_ID',
    defaultValue: 'Agatah Check Unlimited',
  );
}

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final configuration = PurchasesConfiguration(
        RevenueCatConfig.publicApiKey,
      )..appUserID = null;

      await Purchases.configure(configuration);
      _initialized = true;
      debugPrint(
        'RevenueCat: Initialized successfully (platform: ${kIsWeb ? "web" : defaultTargetPlatform})',
      );
    } catch (e) {
      debugPrint('RevenueCat: Initialization failed: $e');
    }
  }

  Future<void> login(String userId) async {
    if (!_initialized) return;
    try {
      await Purchases.logIn(userId);
      debugPrint('RevenueCat: Logged in user $userId');
    } catch (e) {
      debugPrint('RevenueCat: Login failed: $e');
    }
  }

  Future<void> logout() async {
    if (!_initialized) return;
    try {
      final isAnonymous = await Purchases.isAnonymous;
      if (!isAnonymous) {
        await Purchases.logOut();
        debugPrint('RevenueCat: Logged out');
      }
    } catch (e) {
      debugPrint('RevenueCat: Logout failed: $e');
    }
  }

  Future<SubscriptionStatus> getSubscriptionStatus() async {
    if (!_initialized) return SubscriptionStatus.free;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _mapCustomerInfo(customerInfo);
    } catch (e) {
      debugPrint('RevenueCat: Failed to get customer info: $e');
      return SubscriptionStatus.free;
    }
  }

  Future<List<Offering>> getOfferings() async {
    if (!_initialized) return [];

    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) return [];
      return [offerings.current!];
    } catch (e) {
      debugPrint('RevenueCat: Failed to get offerings: $e');
      return [];
    }
  }

  Future<PurchaseOutcome> purchasePackage(Package package) async {
    if (!_initialized) return const PurchaseOutcome.failed();

    try {
      // ignore: deprecated_member_use
      final result = await Purchases.purchasePackage(package);
      final status = _mapCustomerInfo(result.customerInfo);
      if (status.hasUnlimited) {
        return PurchaseOutcome.success(status);
      }
      return const PurchaseOutcome.pendingUnconfirmed();
    } catch (e) {
      if (e is PlatformException) {
        final errorCode = PurchasesErrorHelper.getErrorCode(e);
        if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
          debugPrint('RevenueCat: Purchase cancelled by user');
          return const PurchaseOutcome.cancelled();
        }
        debugPrint('RevenueCat: Purchase error: $errorCode');
      } else {
        debugPrint('RevenueCat: Purchase failed: $e');
      }
      return const PurchaseOutcome.failed();
    }
  }

  Future<RestoreOutcome> restorePurchases() async {
    if (!_initialized) return const RestoreOutcome.failed();

    try {
      final customerInfo = await Purchases.restorePurchases();
      final status = _mapCustomerInfo(customerInfo);
      if (status.hasUnlimited) {
        return RestoreOutcome.restored(status);
      }
      return const RestoreOutcome.nothingToRestore();
    } catch (e) {
      debugPrint('RevenueCat: Restore failed: $e');
      return const RestoreOutcome.failed();
    }
  }

  void addCustomerInfoListener(void Function(SubscriptionStatus) listener) {
    if (!_initialized) return;
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      listener(_mapCustomerInfo(customerInfo));
    });
  }

  SubscriptionStatus _mapCustomerInfo(CustomerInfo info) {
    final entitlement =
        info.entitlements.active[RevenueCatConfig.entitlementId];
    if (entitlement != null) {
      return SubscriptionStatus(
        tier: SubscriptionTier.unlimited,
        isActive: true,
        expirationDate: entitlement.expirationDate != null
            ? DateTime.tryParse(entitlement.expirationDate!)
            : null,
        managementUrl: info.managementURL,
        productIdentifier: entitlement.productIdentifier,
        willRenew: entitlement.willRenew,
      );
    }
    return SubscriptionStatus(
      tier: SubscriptionTier.free,
      isActive: false,
      managementUrl: info.managementURL,
    );
  }
}
