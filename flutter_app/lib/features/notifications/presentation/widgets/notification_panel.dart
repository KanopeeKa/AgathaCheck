import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/experience_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_kind.dart';
import '../../domain/entities/notification_scope.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_date_groups.dart';
import '../widgets/notification_tile.dart';

/// Full-height right slide-over notification panel (opened via bell → endDrawer).
///
/// Kind-filter chips (All / Care / Organisation) sit above a date-grouped list.
/// "Action needed" chip appears on administrative rows with open referenced objects.
class NotificationPanel extends ConsumerStatefulWidget {
  const NotificationPanel({super.key});

  @override
  ConsumerState<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends ConsumerState<NotificationPanel> {
  NotificationKind? _selectedKind; // null = All

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
    final xp = context.experienceColors;
    final notificationsAsync = ref.watch(notificationsProvider);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.88,
      child: SafeArea(
        child: Column(
          children: [
            _PanelHeader(l: l, theme: theme, onMarkAllRead: _markAllRead),
            _KindFilterChips(
              l: l,
              xp: xp,
              selected: _selectedKind,
              onSelected: (kind) => setState(() => _selectedKind = kind),
            ),
            const Divider(height: 1),
            Expanded(
              child: notificationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorView(
                  error: e,
                  l: l,
                  theme: theme,
                  onRetry: () =>
                      ref.read(notificationsProvider.notifier).refresh(),
                ),
                data: (all) =>
                    _NotificationList(all: all, selectedKind: _selectedKind),
              ),
            ),
          ],
        ),
      ),
    );
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.notifications,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton.icon(
            key: const Key('mark_all_read_button'),
            icon: const Icon(Icons.done_all, size: 18),
            label: Text(l.markAllRead),
            onPressed: onMarkAllRead,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l.close,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _KindFilterChips extends StatelessWidget {
  const _KindFilterChips({
    required this.l,
    required this.xp,
    required this.selected,
    required this.onSelected,
  });

  final AppLocalizations l;
  final ExperienceColors xp;
  final NotificationKind? selected;
  final void Function(NotificationKind?) onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 8,
        children: [
          _FilterChip(
            label: l.notificationKindAll,
            selected: selected == null,
            color: Colors.grey.shade600,
            onTap: () => onSelected(null),
          ),
          _FilterChip(
            label: l.notificationKindCare,
            selected: selected == NotificationKind.care,
            color: xp.guardianPrimary,
            onTap: () => onSelected(NotificationKind.care),
          ),
          _FilterChip(
            label: l.notificationKindOrganisation,
            selected: selected == NotificationKind.administrative,
            color: xp.organizationPrimary,
            onTap: () => onSelected(NotificationKind.administrative),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withAlpha(40),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : null,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: selected ? BorderSide(color: color, width: 1.5) : null,
    );
  }
}

class _NotificationList extends ConsumerWidget {
  const _NotificationList({required this.all, required this.selectedKind});

  final List<AppNotification> all;
  final NotificationKind? selectedKind;

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
        .where((n) => selectedKind == null || n.kind == selectedKind)
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
          ],
        ),
      );
    }

    final grouped = groupNotificationsByDate(context, filtered);

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: grouped.length,
        itemBuilder: (context, i) {
          final group = grouped[i];
          return Column(
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
                (n) => NotificationTile(
                  notification: n,
                  listScope: _scopeForNotification(n),
                  showActionNeeded: _needsAction(n),
                  onTap: () => _onTap(context, ref, n),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  NotificationScope _scopeForNotification(AppNotification n) =>
      n.organizationId != null && n.organizationId!.isNotEmpty
      ? NotificationScope.organization
      : NotificationScope.guardian;

  /// Heuristic: administrative + not resolved + not read → "Action needed".
  bool _needsAction(AppNotification n) =>
      n.kind == NotificationKind.administrative &&
      n.resolvedAt == null &&
      !n.isRead;

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
    if (n.petId != null && n.petId!.isNotEmpty) {
      context.go('/pet/${n.petId}');
    } else if (n.organizationId != null && n.organizationId!.isNotEmpty) {
      context.go('/o/orgs/${n.organizationId}');
    }
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
