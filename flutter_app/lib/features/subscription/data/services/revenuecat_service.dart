import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../domain/entities/subscription_status.dart';

class RevenueCatConfig {
  static const String publicApiKey = 'test_mChvbdszQBlZxZxjoINftJrAbTx';
  static const String entitlementId = 'Agatah Check Unlimited';
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
      final configuration = PurchasesConfiguration(RevenueCatConfig.publicApiKey)
        ..appUserID = null;

      await Purchases.configure(configuration);
      _initialized = true;
      debugPrint('RevenueCat: Initialized successfully (platform: ${kIsWeb ? "web" : defaultTargetPlatform})');
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

  Future<SubscriptionStatus> purchasePackage(Package package) async {
    if (!_initialized) return SubscriptionStatus.free;

    try {
      final result = await Purchases.purchasePackage(package);
      return _mapCustomerInfo(result.customerInfo);
    } catch (e) {
      if (e is PlatformException) {
        final errorCode = PurchasesErrorHelper.getErrorCode(e);
        if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
          debugPrint('RevenueCat: Purchase cancelled by user');
        } else {
          debugPrint('RevenueCat: Purchase error: $errorCode');
        }
      } else {
        debugPrint('RevenueCat: Purchase failed: $e');
      }
      return await getSubscriptionStatus();
    }
  }

  Future<SubscriptionStatus> restorePurchases() async {
    if (!_initialized) return SubscriptionStatus.free;

    try {
      final customerInfo = await Purchases.restorePurchases();
      return _mapCustomerInfo(customerInfo);
    } catch (e) {
      debugPrint('RevenueCat: Restore failed: $e');
      return SubscriptionStatus.free;
    }
  }

  void addCustomerInfoListener(void Function(SubscriptionStatus) listener) {
    if (!_initialized) return;
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      listener(_mapCustomerInfo(customerInfo));
    });
  }

  SubscriptionStatus _mapCustomerInfo(CustomerInfo info) {
    final entitlement = info.entitlements.active[RevenueCatConfig.entitlementId];
    if (entitlement != null) {
      return SubscriptionStatus(
        tier: SubscriptionTier.unlimited,
        isActive: true,
        expirationDate: entitlement.expirationDate != null
            ? DateTime.tryParse(entitlement.expirationDate!)
            : null,
        managementUrl: info.managementURL,
        productIdentifier: entitlement.productIdentifier,
      );
    }
    return SubscriptionStatus(
      tier: SubscriptionTier.free,
      isActive: false,
      managementUrl: info.managementURL,
    );
  }
}
