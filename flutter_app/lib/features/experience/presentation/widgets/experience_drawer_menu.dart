import 'package:flutter/material.dart';

import '../../domain/entities/drawer_menu_item.dart';
import 'experience_drawer_menu_item.dart';

/// Renders config-driven drawer sections on a neutral background.
class ExperienceDrawerMenu extends StatelessWidget {
  const ExperienceDrawerMenu({
    super.key,
    required this.entries,
    required this.onItemTap,
    this.activeSemanticKey,
  });

  final List<DrawerMenuEntry> entries;
  final void Function(DrawerMenuItem item) onItemTap;

  /// Highlights the row matching this semantic key (current section).
  final String? activeSemanticKey;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (final entry in entries) {
      if (entry.isSeparator) {
        if (children.isNotEmpty) {
          children.add(const Divider(height: 1));
        }
        continue;
      }

      final item = entry.item!;
      children.add(
        ExperienceDrawerMenuItem(
          key: Key(item.semanticKey),
          item: item,
          isActive: item.semanticKey == activeSemanticKey,
          onTap: () => onItemTap(item),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: children,
    );
  }
}
