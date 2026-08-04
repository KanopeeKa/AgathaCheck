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
    final combinedUnread = ref.watch(combinedUnreadNotificationCountProvider);
    final bellTooltip = combinedUnread > 0
        ? l.drawerItemUnreadSemantics(
            l.notificationsBellTooltip,
            combinedUnread,
          )
        : l.notificationsBellTooltip;
    final bellIcon = combinedUnread > 0
        ? Badge(
            isLabelVisible: true,
            label: Text('$combinedUnread'),
            child: const Icon(Icons.notifications_outlined),
          )
        : const Icon(Icons.notifications_outlined);

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
