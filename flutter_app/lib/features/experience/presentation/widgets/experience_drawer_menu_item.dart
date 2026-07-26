import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/experience_colors.dart';
import '../../domain/entities/drawer_menu_group.dart';
import '../../domain/entities/drawer_menu_item.dart';

/// Accent colour for a drawer row icon and active indicator.
Color drawerGroupAccent(BuildContext context, DrawerMenuGroup group) {
  final xp = context.experienceColors;
  return switch (group) {
    DrawerMenuGroup.guardianPlum => xp.guardianPrimary,
    DrawerMenuGroup.organizationGreen => xp.organizationPrimary,
    DrawerMenuGroup.utility => Theme.of(context).colorScheme.onSurfaceVariant,
  };
}

/// Single drawer row with icon, label, and optional active-state accent.
class ExperienceDrawerMenuItem extends StatelessWidget {
  const ExperienceDrawerMenuItem({
    super.key,
    required this.item,
    required this.onTap,
    this.isActive = false,
  });

  final DrawerMenuItem item;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = drawerGroupAccent(context, item.group);

    Widget label = Text(
      item.label,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
        color: isActive ? accent : null,
      ),
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
      selected: isActive,
      label: item.hasBadge
          ? '${item.label}, ${item.badgeCount} unread'
          : item.label,
      child: Material(
        color: isActive ? AppColorTokens.surfaceAlt : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                if (isActive) Container(width: 3, height: 48, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        if (item.icon != null) ...[
                          Icon(item.icon, size: 22, color: accent),
                          const SizedBox(width: 12),
                        ],
                        Expanded(child: label),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
