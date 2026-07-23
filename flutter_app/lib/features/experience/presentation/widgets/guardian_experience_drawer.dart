import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/experience_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../config/drawer_menu_config.dart';
import '../providers/experience_providers.dart';
import '../utils/drawer_menu_actions.dart';
import 'experience_drawer_menu.dart';

/// Guardian experience hamburger menu.
class GuardianExperienceDrawer extends ConsumerWidget {
  const GuardianExperienceDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final unread = ref.watch(guardianUnreadNotificationCountProvider);
    final xp = context.experienceColors;
    final entries = DrawerMenuConfig.guardianEntries(
      l: l,
      notificationUnread: unread,
    );

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: xp.guardianPrimary),
              accountName: Text(
                auth.user?.firstName?.isNotEmpty == true
                    ? auth.user!.firstName!
                    : (auth.user?.email ?? ''),
              ),
              accountEmail: Text(auth.user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                child: Text(
                  (auth.user?.firstName?.isNotEmpty == true
                          ? auth.user!.firstName![0]
                          : auth.user?.email[0] ?? 'U')
                      .toUpperCase(),
                ),
              ),
            ),
            Expanded(
              child: ExperienceDrawerMenu(
                entries: entries,
                onItemTap: (item) =>
                    handleExperienceDrawerItemTap(context, ref, item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
