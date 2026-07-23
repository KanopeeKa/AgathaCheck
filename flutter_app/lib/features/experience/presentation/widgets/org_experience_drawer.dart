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

/// Organisation experience hamburger menu.
class OrgExperienceDrawer extends ConsumerWidget {
  const OrgExperienceDrawer({
    super.key,
    required this.showGuardianView,
    required this.isFosterPortal,
  });

  final bool showGuardianView;
  final bool isFosterPortal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final orgUnread = ref.watch(orgUnreadNotificationCountProvider);
    final xp = context.experienceColors;
    final entries = DrawerMenuConfig.organizationEntries(
      l: l,
      orgNotificationUnread: orgUnread,
      showGuardianView: showGuardianView,
      isFosterPortal: isFosterPortal,
    );

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: xp.organizationPrimary),
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
