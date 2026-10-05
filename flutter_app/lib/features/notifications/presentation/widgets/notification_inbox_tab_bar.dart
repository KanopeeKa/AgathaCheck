import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/services/notification_inbox_v2_rules.dart';

class NotificationInboxTabBar extends StatelessWidget {
  const NotificationInboxTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.activityIndicatorCount,
    required this.forYouShowDot,
  });

  final NotificationInboxTab selected;
  final ValueChanged<NotificationInboxTab> onSelected;
  final int activityIndicatorCount;
  final bool forYouShowDot;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _InboxTab(
              label: l.notificationInboxTabActivity,
              selected: selected == NotificationInboxTab.activity,
              count: activityIndicatorCount,
              onTap: () => onSelected(NotificationInboxTab.activity),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _InboxTab(
              label: l.notificationInboxTabForYou,
              selected: selected == NotificationInboxTab.forYou,
              showDot: forYouShowDot,
              onTap: () => onSelected(NotificationInboxTab.forYou),
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxTab extends StatelessWidget {
  const _InboxTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count = 0,
    this.showDot = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int count;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer.withAlpha(80)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  _CountBadge(count: count),
                ] else if (showDot) ...[
                  const SizedBox(width: 6),
                  _DotBadge(color: theme.colorScheme.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DotBadge extends StatelessWidget {
  const _DotBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
