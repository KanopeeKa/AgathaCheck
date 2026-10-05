import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_scope.dart';
import '../../domain/services/notification_inline_action_support.dart';
import '../../domain/services/notification_inbox_v2_rules.dart';
import '../providers/notification_providers.dart';
import '../utils/notification_navigation.dart';
import 'notification_inbox_row.dart'
    show NotificationInboxRow, NotificationInboxTileTap;
import 'notification_date_groups.dart';
import 'notification_suggestion_card.dart';
import 'notification_tile.dart';

/// Date-grouped inbox list with Activity pinned sections (FR-IN-3/4).
class NotificationInboxList extends ConsumerWidget {
  const NotificationInboxList({
    super.key,
    required this.notifications,
    required this.selectedTab,
    this.listScope = NotificationScope.guardian,
    this.onNotificationTap,
  });

  final List<AppNotification> notifications;
  final NotificationInboxTab selectedTab;
  final NotificationScope listScope;
  final NotificationInboxTileTap? onNotificationTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider).valueOrNull;
    final mutedIds = prefs?.mutedPetIds.toSet() ?? {};
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    final filtered = notifications
        .where(
          (n) =>
              n.petId == null ||
              n.petId!.isEmpty ||
              !mutedIds.contains(n.petId),
        )
        .where((n) => NotificationInboxV2Rules.belongsToTab(n, selectedTab))
        .toList();

    if (filtered.isEmpty) {
      final emptyCopy = selectedTab == NotificationInboxTab.forYou
          ? l.notificationInboxForYouEmpty
          : l.notificationInboxActivityEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                emptyCopy,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    final needsResponse = filtered
        .where(NotificationInboxV2Rules.needsResponse)
        .where((n) => !NotificationInboxV2Rules.isUrgent(n))
        .toList();
    final needsResponseIds = needsResponse
        .map((notification) => notification.id)
        .toSet();

    final pinnedUrgent = selectedTab == NotificationInboxTab.activity
        ? filtered
              .where(
                (n) =>
                    NotificationInboxV2Rules.isUrgent(n) &&
                    !needsResponseIds.contains(n.id),
              )
              .toList()
        : const <AppNotification>[];
    final pinnedIds = {...needsResponseIds, ...pinnedUrgent.map((n) => n.id)};

    if (selectedTab == NotificationInboxTab.forYou) {
      return RefreshIndicator(
        onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
        child: _forYouSuggestionsList(context, ref, filtered, theme),
      );
    }

    final grouped = groupNotificationsByDate(
      context,
      filtered.where((n) => !pinnedIds.contains(n.id)).toList(),
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
            ...pinnedUrgent.map((n) => _tile(context, ref, n)),
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
            ...needsResponse.map((n) => _tile(context, ref, n)),
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
                ...group.notifications.map((n) => _tile(context, ref, n)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, AppNotification n) {
    final inline = NotificationInlineActionSupport.supportsInlineActions(n);
    if (inline) {
      return NotificationInboxRow(
        notification: n,
        listScope: listScope,
        onNotificationTap: onNotificationTap,
      );
    }
    return NotificationTile(
      notification: n,
      listScope: listScope,
      showActionNeeded: NotificationInboxV2Rules.needsResponse(n),
      onTap: () async {
        if (onNotificationTap != null) {
          await onNotificationTap!(context, ref, n);
          return;
        }
        if (!n.isRead) {
          await ref.read(notificationsProvider.notifier).markAsRead(n.id);
        }
        if (!context.mounted) return;
        navigateFromNotification(context, n);
      },
    );
  }

  Widget _forYouSuggestionsList(
    BuildContext context,
    WidgetRef ref,
    List<AppNotification> suggestions,
    ThemeData theme,
  ) {
    final byPet = <String, List<AppNotification>>{};
    for (final n in suggestions) {
      final key = n.petId ?? '';
      byPet.putIfAbsent(key, () => []).add(n);
    }
    final petKeys = byPet.keys.toList()
      ..sort((a, b) {
        final aName = byPet[a]?.first.petName ?? '';
        final bName = byPet[b]?.first.petName ?? '';
        return aName.compareTo(bName);
      });

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final petKey in petKeys) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              formatPetGroupHeader(byPet[petKey]?.first.petName),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...byPet[petKey]!.map(
            (n) => NotificationSuggestionCard(
              notification: n,
              onOpenPet: () {
                final petId = n.petId;
                if (petId != null && petId.isNotEmpty) {
                  navigateFromNotification(context, n);
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}
