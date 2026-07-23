import 'package:flutter/material.dart';

import '../../domain/entities/drawer_menu_item.dart';

/// Single text-first drawer row (minimum 48dp touch target).
class ExperienceDrawerMenuItem extends StatelessWidget {
  const ExperienceDrawerMenuItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  final DrawerMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget label = Text(
      item.label,
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
    );

    if (item.hasBadge) {
      label = Badge(
        isLabelVisible: true,
        label: Text('${item.badgeCount}'),
        child: label,
      );
    }

    return Semantics(
      button: true,
      label: item.hasBadge
          ? '${item.label}, ${item.badgeCount} unread'
          : item.label,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Align(alignment: Alignment.centerLeft, child: label),
          ),
        ),
      ),
    );
  }
}
