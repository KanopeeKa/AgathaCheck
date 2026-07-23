import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/experience_colors.dart';
import '../../domain/entities/drawer_menu_group.dart';
import '../../domain/entities/drawer_menu_item.dart';
import 'experience_drawer_menu_item.dart';

/// Background fill for a drawer menu group (no borders).
Color drawerGroupBackground(
  BuildContext context,
  DrawerMenuGroup group,
) {
  final xp = context.experienceColors;
  return switch (group) {
    DrawerMenuGroup.guardianPlum => xp.guardianLight,
    DrawerMenuGroup.organizationGreen => xp.organizationLight,
    DrawerMenuGroup.utility => AppColorTokens.surfaceAlt,
  };
}

/// Renders config-driven drawer sections with semantic group backgrounds.
class ExperienceDrawerMenu extends StatelessWidget {
  const ExperienceDrawerMenu({
    super.key,
    required this.entries,
    required this.onItemTap,
  });

  final List<DrawerMenuEntry> entries;
  final void Function(DrawerMenuItem item) onItemTap;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry.isSeparator) {
        if (children.isNotEmpty) {
          children.add(const Divider(height: 1));
        }
        continue;
      }

      final item = entry.item!;
      final groupBg = drawerGroupBackground(context, item.group);
      final prevGroup = i > 0 && !entries[i - 1].isSeparator
          ? entries[i - 1].item!.group
          : null;
      final nextIsSeparator =
          i + 1 < entries.length && entries[i + 1].isSeparator;
      final nextGroup = i + 1 < entries.length && !entries[i + 1].isSeparator
          ? entries[i + 1].item!.group
          : null;

      final topRadius = prevGroup != item.group ? 12.0 : 0.0;
      final bottomRadius = nextIsSeparator || nextGroup != item.group
          ? 12.0
          : 0.0;

      children.add(
        Padding(
          padding: EdgeInsets.only(
            top: prevGroup != item.group ? 8 : 0,
            bottom: nextIsSeparator || nextGroup != item.group ? 8 : 0,
          ),
          child: Material(
            color: groupBg,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(topRadius),
              bottom: Radius.circular(bottomRadius),
            ),
            child: ExperienceDrawerMenuItem(
              key: Key(item.semanticKey),
              item: item,
              onTap: () => onItemTap(item),
            ),
          ),
        ),
      );
    }

    return ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: children);
  }
}
