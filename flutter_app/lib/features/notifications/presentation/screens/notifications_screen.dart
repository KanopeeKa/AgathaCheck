import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_scope.dart';
import '../../domain/services/notification_inbox_v2_rules.dart';
import '../../domain/services/notification_scope_rules.dart';
import '../providers/notification_inbox_session.dart';
import '../providers/notification_providers.dart';
import '../utils/notification_navigation.dart';
import '../widgets/notification_inbox_list.dart';
import '../widgets/notification_inbox_tab_bar.dart';
import '../widgets/notification_inbox_v2_explainer.dart';
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
    final selectedTab = ref.watch(notificationInboxSessionTabProvider);

    final prefs = ref.watch(notificationPreferencesProvider).valueOrNull;
    final mutedIds = prefs?.mutedPetIds.toSet() ?? {};
    final pets = ref.watch(petListProvider).valueOrNull ?? [];

    List<AppNotification> scoped(List<AppNotification> all) =>
        NotificationScopeRules.filter(
          all,
          _effectiveScope,
          pets,
          mutedPetIds: mutedIds,
        );

    final visible = notificationsAsync.valueOrNull == null
        ? const <AppNotification>[]
        : scoped(notificationsAsync.valueOrNull!);

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
          final notifications = scoped(allNotifications);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NotificationInboxTabBar(
                selected: selectedTab,
                onSelected: (tab) =>
                    ref
                            .read(notificationInboxSessionTabProvider.notifier)
                            .state =
                        tab,
                activityIndicatorCount:
                    NotificationInboxV2Rules.activityTabIndicatorCount(visible),
                forYouShowDot: NotificationInboxV2Rules.forYouTabShowDot(
                  visible,
                ),
              ),
              NotificationInboxV2Explainer(
                onOpenActions: (context) =>
                    navigateToNotificationActions(context),
              ),
              Expanded(
                child: NotificationInboxList(
                  notifications: notifications,
                  selectedTab: selectedTab,
                  listScope: _effectiveScope,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
