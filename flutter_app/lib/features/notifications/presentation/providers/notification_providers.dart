import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_scope.dart';
import '../../domain/services/notification_scope_rules.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationDataSourceProvider = Provider<NotificationRemoteDataSource>((
  ref,
) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return NotificationRemoteDataSourceImpl(
    baseUrl: baseUrl,
    client: ref.watch(authHttpClientProvider),
  );
});

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
      NotificationsNotifier.new,
    );

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn || auth.accessToken == null) return [];
    return _getRepo().getNotifications();
  }

  NotificationRepository _getRepo() {
    final dataSource = ref.read(notificationDataSourceProvider);
    final auth = ref.read(authProvider);
    if (auth.accessToken == null) {
      throw Exception('Not authenticated');
    }
    return NotificationRepositoryImpl(dataSource, () => auth.accessToken!);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> markAsRead(String id) async {
    await _getRepo().markAsRead(id);
    await refresh();
  }

  Future<void> markAllAsRead() async {
    await _getRepo().markAllAsRead();
    await refresh();
  }

  Future<void> checkDueEntries() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn || auth.accessToken == null) return;
    try {
      final pets = ref.read(petListProvider).valueOrNull ?? [];
      final petNames = {for (final p in pets) p.id: p.name};
      await _getRepo().checkDueEntries(petNames: petNames);
      await refresh();
    } catch (_) {}
  }
}

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(guardianUnreadNotificationCountProvider);
});

/// Combined unread count across both kinds and all scopes, respecting muted pets.
final combinedUnreadNotificationCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider);
  final prefs = ref.watch(notificationPreferencesProvider).valueOrNull;
  final mutedIds = prefs?.mutedPetIds.toSet() ?? {};
  return notifs.whenOrNull(
        data: (list) => list
            .where((n) => !n.isRead)
            .where(
              (n) =>
                  n.petId == null ||
                  n.petId!.isEmpty ||
                  !mutedIds.contains(n.petId),
            )
            .length,
      ) ??
      0;
});

final guardianUnreadNotificationCountProvider = Provider<int>((ref) {
  return _scopedUnreadCount(ref, NotificationScope.guardian);
});

final orgUnreadNotificationCountProvider = Provider<int>((ref) {
  return _scopedUnreadCount(ref, NotificationScope.organization);
});

int _scopedUnreadCount(Ref ref, NotificationScope scope) {
  final notifs = ref.watch(notificationsProvider);
  final prefs = ref.watch(notificationPreferencesProvider).valueOrNull;
  final pets = ref.watch(petListProvider).valueOrNull ?? [];
  final mutedIds = prefs?.mutedPetIds.toSet() ?? {};
  return notifs.whenOrNull(
        data: (list) => NotificationScopeRules.unreadCount(
          list,
          scope,
          pets,
          mutedPetIds: mutedIds,
        ),
      ) ??
      0;
}

final notificationPreferencesProvider =
    AsyncNotifierProvider<
      NotificationPreferencesNotifier,
      NotificationPreferences
    >(NotificationPreferencesNotifier.new);

class NotificationPreferencesNotifier
    extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn || auth.accessToken == null) {
      return const NotificationPreferences();
    }
    return _getRepo().getPreferences();
  }

  NotificationRepository _getRepo() {
    final dataSource = ref.read(notificationDataSourceProvider);
    final auth = ref.read(authProvider);
    if (auth.accessToken == null) {
      throw Exception('Not authenticated');
    }
    return NotificationRepositoryImpl(dataSource, () => auth.accessToken!);
  }

  Future<void> updatePreferences(NotificationPreferences prefs) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _getRepo().updatePreferences(prefs));
  }
}
