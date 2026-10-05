import '../data/services/revenuecat_service.dart';

/// Initializes the subscription SDK before the app shell mounts.
Future<void> initializeSubscriptionSdk() => RevenueCatService().initialize();
