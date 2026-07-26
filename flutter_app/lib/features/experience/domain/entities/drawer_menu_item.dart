import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData;

import 'drawer_menu_group.dart';

/// One text-first row in the experience drawer (config-driven navigation v2).
@immutable
class DrawerMenuItem {
  const DrawerMenuItem({
    required this.semanticKey,
    required this.label,
    required this.group,
    this.icon,
    this.badgeCount = 0,
    this.onTap,
    this.route,
  }) : assert(
         onTap != null || route != null,
         'DrawerMenuItem needs onTap or route',
       );

  /// Stable key for tests and semantics (e.g. drawer_my_pets).
  final String semanticKey;

  final String label;
  final DrawerMenuGroup group;
  final IconData? icon;
  final int badgeCount;
  final VoidCallback? onTap;
  final String? route;

  bool get hasBadge => badgeCount > 0;
}

/// Visual separator between drawer groups.
@immutable
class DrawerMenuSeparator {
  const DrawerMenuSeparator();
}

/// Union of drawer rows: item or separator.
@immutable
class DrawerMenuEntry {
  const DrawerMenuEntry.item(this.item) : separator = null;
  const DrawerMenuEntry.separator()
    : item = null,
      separator = const DrawerMenuSeparator();

  final DrawerMenuItem? item;
  final DrawerMenuSeparator? separator;

  bool get isSeparator => separator != null;
}
