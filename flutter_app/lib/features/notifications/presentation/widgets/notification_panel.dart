import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/services/notification_inbox_v2_rules.dart';
import '../widgets/notification_inbox_tab_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_scope.dart';
import '../providers/notification_providers.dart';
import '../utils/notification_navigation.dart';
import '../widgets/notification_date_groups.dart';
import '../widgets/notification_tile.dart';

/// Full-height right slide-over notification panel (opened via bell → endDrawer).
///
/// Notifications v2: Activity / For you tabs and calm badge rules (§5.4).
class NotificationPanel extends ConsumerStatefulWidget {
  const NotificationPanel({super.key});

  @override
  ConsumerState<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends ConsumerState<NotificationPanel> {
  NotificationInboxTab _selectedTab = NotificationInboxTab.activity;

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
    final prefs = ref.watch(notificationPreferencesProvider).valueOrNull;
    final mutedIds = prefs?.mutedPetIds.toSet() ?? {};
    final visible = notificationsAsync.valueOrNull
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
              _PanelHeader(l: l, theme: theme, onMarkAllRead: _markAllRead),
              NotificationInboxTabBar(
                selected: _selectedTab,
                onSelected: (tab) => setState(() => _selectedTab = tab),
                activityIndicatorCount:
                    NotificationInboxV2Rules.activityTabIndicatorCount(visible),
                forYouShowDot:
                    NotificationInboxV2Rules.forYouTabShowDot(visible),
              ),
              const Divider(height: 1),
              Expanded(
                child: notificationsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _ErrorView(
                    error: e,
                    l: l,
                    theme: theme,
                    onRetry: () =>
                        ref.read(notificationsProvider.notifier).refresh(),
                  ),
                  data: (all) => _NotificationList(
                    all: all,
                    selectedTab: _selectedTab,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.l,
    required this.theme,
    required this.onMarkAllRead,
  });

  final AppLocalizations l;
  final ThemeData theme;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.notifications,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                _headerIconButton(
                  icon: Icons.settings_outlined,
                  tooltip: l.notificationSettingsTooltip,
                  onPressed: () {
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.push('/notifications/settings');
                  },
                ),
                TextButton.icon(
                  key: const Key('mark_all_read_button'),
                  icon: const Icon(Icons.done_all, size: 18),
                  label: Text(l.markAllRead),
                  onPressed: onMarkAllRead,
                ),
                _headerIconButton(
                  icon: Icons.close,
                  tooltip: l.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _headerIconButton({
  required IconData icon,
  required String tooltip,
  required VoidCallback onPressed,
}) {
  return Semantics(
    button: true,
    label: tooltip,
    child: ExcludeSemantics(
      child: IconButton(icon: Icon(icon), onPressed: onPressed),
    ),
  );
}

class _NotificationList extends ConsumerWidget {
  const _NotificationList({required this.all, required this.selectedTab});

  final List<AppNotification> all;
  final NotificationInboxTab selectedTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider).valueOrNull;
    final mutedIds = prefs?.mutedPetIds.toSet() ?? {};
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    final filtered = all
        .where(
          (n) =>
              n.petId == null ||
              n.petId!.isEmpty ||
              !mutedIds.contains(n.petId),
        )
        .where((n) => NotificationInboxV2Rules.belongsToTab(n, selectedTab))
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(l.noNotifications, style: theme.textTheme.bodyLarge),
            if (selectedTab == NotificationInboxTab.forYou) ...[
              const SizedBox(height: 4),
              Text(
                l.notificationInboxTabForYou,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final needsResponse = filtered
        .where(NotificationInboxV2Rules.needsResponse)
        .where((n) => !NotificationInboxV2Rules.isUrgent(n))
        .toList();
    final needsResponseIds =
        needsResponse.map((notification) => notification.id).toSet();

    final pinnedUrgent = selectedTab == NotificationInboxTab.activity
        ? filtered
            .where(
              (n) =>
                  NotificationInboxV2Rules.isUrgent(n) &&
                  !needsResponseIds.contains(n.id),
            )
            .toList()
        : const <AppNotification>[];
    final pinnedIds = {
      ...needsResponseIds,
      ...pinnedUrgent.map((n) => n.id),
    };

    final grouped = groupNotificationsByDate(
      context,
      filtered.where((notification) => !pinnedIds.contains(notification.id)).toList(),
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (pinnedUrgent.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                l.notificationUrgent,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            ...pinnedUrgent.map((notification) => _tile(context, ref, notification)),
          ],
          if (needsResponse.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                l.notificationNeedsResponse,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...needsResponse.map((notification) => _tile(context, ref, notification)),
          ],
          ...grouped.map(
            (group) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    group.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ...group.notifications.map(
                  (notification) => _tile(context, ref, notification),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    return NotificationTile(
      notification: notification,
      listScope: _scopeForNotification(notification),
      showActionNeeded: _needsAction(notification),
      onTap: () => _onTap(context, ref, notification),
    );
  }

  NotificationScope _scopeForNotification(AppNotification n) =>
      n.organizationId != null && n.organizationId!.isNotEmpty
      ? NotificationScope.organization
      : NotificationScope.guardian;

  /// Administrative resolution is independent from a user's read state.
  bool _needsAction(AppNotification n) =>
      NotificationInboxV2Rules.needsResponse(n);

  Future<void> _onTap(
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
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.error,
    required this.l,
    required this.theme,
    required this.onRetry,
  });

  final Object error;
  final AppLocalizations l;
  final ThemeData theme;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            l.failedToLoadNotifications(error.toString()),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: onRetry, child: Text(l.retry)),
        ],
      ),
    );
  }
}
