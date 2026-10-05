import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../features/notifications/presentation/providers/notification_providers.dart';

/// Notification bell with unread badge for experience/org shells.
class ShellNotificationBell extends ConsumerWidget {
  const ShellNotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final indicator = ref.watch(notificationBellIndicatorProvider);
    final count = indicator.numericCount;
    final bellTooltip = count > 0
        ? l.drawerItemUnreadSemantics(l.notificationsBellTooltip, count)
        : indicator.showDot
        ? l.notificationsBellTooltip
        : l.notificationsBellTooltip;
    final Widget bellIcon;
    if (count > 0) {
      bellIcon = Badge(
        isLabelVisible: true,
        label: Text('$count'),
        child: const Icon(Icons.notifications_outlined),
      );
    } else if (indicator.showDot) {
      bellIcon = const Badge(
        isLabelVisible: true,
        smallSize: 8,
        child: Icon(Icons.notifications_outlined),
      );
    } else {
      bellIcon = const Icon(Icons.notifications_outlined);
    }

    return Semantics(
      button: true,
      label: bellTooltip,
      child: ExcludeSemantics(
        child: IconButton(
          key: const Key('experience_notification_bell'),
          icon: bellIcon,
          onPressed: () => Scaffold.of(context).openEndDrawer(),
        ),
      ),
    );
  }
}
