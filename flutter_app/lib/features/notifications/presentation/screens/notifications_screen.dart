import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/notification_scope.dart';
import '../../domain/services/notification_scope_rules.dart';
import '../providers/notification_providers.dart';
import '../utils/notification_accent.dart';
import '../utils/notification_navigation.dart';
import '../widgets/notification_date_groups.dart';
import '../widgets/notification_tile.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key, this.backPath = '/', this.scope});

  final String backPath;

  /// When null, scope is inferred from [backPath] (`/o/*` → organisation).
  final NotificationScope? scope;

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationScope get _effectiveScope {
    final explicit = widget.scope;
    if (explicit != null) return explicit;
    return widget.backPath.startsWith('/o/')
        ? NotificationScope.organization
        : NotificationScope.guardian;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationsProvider.notifier).checkDueEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final accent = resolveNotificationAccent(context, _effectiveScope);

    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: l.notifications),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l.goBack,
          onPressed: () => context.go(widget.backPath),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l.notificationSettingsTooltip,
            onPressed: () => context.push('/notifications/settings'),
          ),
          TextButton.icon(
            key: const Key('mark_all_read_button'),
            icon: const Icon(Icons.done_all, size: 18),
            label: Text(l.markAllRead),
            onPressed: () async {
              await ref.read(notificationsProvider.notifier).markAllAsRead();
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l.markAllRead)));
              }
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('Failed to load notifications: $error'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).refresh(),
                child: Text(l.retry),
              ),
            ],
          ),
        ),
        data: (allNotifications) {
          final prefs = ref.watch(notificationPreferencesProvider).valueOrNull;
          final mutedIds = prefs?.mutedPetIds.toSet() ?? {};
          final pets = ref.watch(petListProvider).valueOrNull ?? [];
          final notifications = NotificationScopeRules.filter(
            allNotifications,
            _effectiveScope,
            pets,
            mutedPetIds: mutedIds,
          );

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(l.noNotifications, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up! Notifications will appear\nwhen health entries are due.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final grouped = groupNotificationsByDate(context, notifications);

          return RefreshIndicator(
            onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final group = grouped[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        group.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: accent.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...group.notifications.map(
                      (n) => NotificationTile(
                        notification: n,
                        listScope: _effectiveScope,
                        onTap: () async {
                          if (!n.isRead) {
                            await ref
                                .read(notificationsProvider.notifier)
                                .markAsRead(n.id);
                          }
                          if (!context.mounted) return;
                          navigateFromNotification(context, n);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
