import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/services/notification_inbox_v2_rules.dart';
import '../providers/notification_inbox_session.dart';
import '../providers/notification_providers.dart';
import '../utils/notification_navigation.dart';
import 'notification_inbox_list.dart';
import 'notification_inbox_tab_bar.dart';
import 'notification_inbox_v2_explainer.dart';
import 'notification_panel_error_view.dart';
import 'notification_panel_header.dart';

/// Full-height right slide-over notification panel (opened via bell → endDrawer).
///
/// Notifications v2: Activity / For you tabs and calm badge rules (§5.4).
class NotificationPanel extends ConsumerStatefulWidget {
  const NotificationPanel({super.key});

  @override
  ConsumerState<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends ConsumerState<NotificationPanel> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(notificationsProvider.notifier).checkDueEntries(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsProvider);
    final selectedTab = ref.watch(notificationInboxSessionTabProvider);
    final prefs = ref.watch(notificationPreferencesProvider).valueOrNull;
    final mutedIds = prefs?.mutedPetIds.toSet() ?? {};
    final visible =
        notificationsAsync.valueOrNull
            ?.where(
              (n) =>
                  n.petId == null ||
                  n.petId!.isEmpty ||
                  !mutedIds.contains(n.petId),
            )
            .toList() ??
        const <AppNotification>[];

    return Drawer(
      width: _panelWidth(context),
      child: SafeArea(
        child: FocusTraversalGroup(
          child: Column(
            children: [
              NotificationPanelHeader(
                l: l,
                theme: theme,
                onMarkAllRead: _markAllRead,
              ),
              NotificationInboxTabBar(
                selected: selectedTab,
                onSelected: (tab) {
                  ref.read(notificationInboxSessionTabProvider.notifier).state =
                      tab;
                  if (tab == NotificationInboxTab.forYou) {
                    ref
                        .read(notificationsProvider.notifier)
                        .markForYouSuggestionsSeen();
                  }
                },
                activityIndicatorCount:
                    NotificationInboxV2Rules.activityTabIndicatorCount(visible),
                forYouShowDot: NotificationInboxV2Rules.forYouTabShowDot(
                  visible,
                ),
              ),
              const NotificationInboxV2Explainer(
                onOpenActions: _openActionsFromPanel,
              ),
              const Divider(height: 1),
              Expanded(
                child: notificationsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => NotificationPanelErrorView(
                    error: e,
                    l: l,
                    theme: theme,
                    onRetry: () =>
                        ref.read(notificationsProvider.notifier).refresh(),
                  ),
                  data: (all) => NotificationInboxList(
                    notifications: all,
                    selectedTab: selectedTab,
                    onNotificationTap: _onPanelNotificationTap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _openActionsFromPanel(BuildContext context) {
    Navigator.of(context).pop();
    navigateToNotificationActions(context);
  }

  Future<void> _onPanelNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
  ) async {
    if (!n.isRead) {
      await ref.read(notificationsProvider.notifier).markAsRead(n.id);
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
    navigateFromNotification(context, n);
  }

  double _panelWidth(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return screenWidth > 600 ? 480 : screenWidth * 0.92;
  }

  Future<void> _markAllRead() async {
    await ref.read(notificationsProvider.notifier).markAllAsRead();
    if (mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.markAllRead)));
    }
  }
}
