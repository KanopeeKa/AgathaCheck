import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/app_experience.dart';
import '../config/drawer_menu_config.dart';
import '../utils/drawer_menu_actions.dart';
import 'experience_drawer_identity_header.dart';
import 'experience_drawer_menu.dart';

/// Unified, full-height section-switcher drawer.
///
/// Brand and close controls stay at the top; Guardian and Organisation are the
/// only scrollable section choices; Account is a quiet, bottom-pinned utility.
class ExperienceSectionDrawer extends ConsumerWidget {
  const ExperienceSectionDrawer({super.key});

  String? _activeSemanticKey({required String location}) {
    if (location == '/account') return 'drawer_account';
    if (location.startsWith('/pc/') || location.startsWith('/g/')) {
      return 'drawer_pet_care';
    }
    if (location.startsWith('/o/')) return 'drawer_organisation';
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final location = GoRouter.maybeOf(context)?.state.uri.path ?? '/';
    final activeExperience = location.startsWith('/o/')
        ? AppExperience.organization
        : AppExperience.petCare;
    final activeKey = _activeSemanticKey(location: location);
    final topEntries = DrawerMenuConfig.sectionSwitcherEntries(l: l);
    final accountItem = DrawerMenuConfig.accountItem(l);

    return Drawer(
      backgroundColor: AppColorTokens.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExperienceDrawerBrandHeader(
              experience: activeExperience,
              brandLabel: l.appTitle,
              logoLabel: l.agathaCheckLogo,
              closeTooltip: l.close,
              onClose: () => Navigator.pop(context),
            ),
            const Divider(height: 1),
            Expanded(
              child: ExperienceDrawerMenu(
                entries: topEntries,
                activeSemanticKey: activeKey,
                onItemTap: (item) =>
                    handleExperienceDrawerItemTap(context, ref, item),
              ),
            ),
            const Divider(height: 1),
            ExperienceDrawerIdentityHeader(
              user: auth.user,
              item: accountItem,
              isActive: activeKey == 'drawer_account',
              onTap: () =>
                  handleExperienceDrawerItemTap(context, ref, accountItem),
            ),
          ],
        ),
      ),
    );
  }
}
