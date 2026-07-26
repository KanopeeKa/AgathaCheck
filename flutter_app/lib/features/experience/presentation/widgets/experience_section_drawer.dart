import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/experience_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../config/drawer_menu_config.dart';
import '../utils/drawer_menu_actions.dart';
import 'experience_drawer_menu.dart';
import 'experience_drawer_menu_item.dart';

/// Unified section-switcher drawer (navigation reversal, phase-1-navigation.md).
///
/// Shows Guardian and Organisation in the main scrollable area, with Account
/// bottom-pinned and visually separated. Identical regardless of current
/// experience mode.
class ExperienceSectionDrawer extends ConsumerWidget {
  const ExperienceSectionDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final xp = context.experienceColors;
    final topEntries = DrawerMenuConfig.sectionSwitcherEntries(l: l);
    final accountItem = DrawerMenuConfig.accountItem(l);

    final displayName = auth.user?.firstName?.isNotEmpty == true
        ? auth.user!.firstName!
        : (auth.user?.email ?? '');
    final initial =
        (auth.user?.firstName?.isNotEmpty == true
                ? auth.user!.firstName![0]
                : auth.user?.email[0] ?? 'U')
            .toUpperCase();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColorTokens.surfaceAlt),
              accountName: Text(
                displayName,
                style: TextStyle(color: xp.guardianPrimary),
              ),
              accountEmail: Text(
                auth.user?.email ?? '',
                style: const TextStyle(color: Color(0xFF757575)),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: xp.guardianLight,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: xp.guardianPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ExperienceDrawerMenu(
                entries: topEntries,
                onItemTap: (item) =>
                    handleExperienceDrawerItemTap(context, ref, item),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Material(
                color: AppColorTokens.surfaceAlt,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: ExperienceDrawerMenuItem(
                  key: const Key('drawer_account'),
                  item: accountItem,
                  onTap: () =>
                      handleExperienceDrawerItemTap(context, ref, accountItem),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
