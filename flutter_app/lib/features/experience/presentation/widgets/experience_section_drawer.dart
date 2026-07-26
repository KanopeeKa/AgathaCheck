import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_experience.dart';
import '../config/drawer_menu_config.dart';
import '../providers/experience_providers.dart';
import '../utils/drawer_menu_actions.dart';
import 'experience_drawer_menu.dart';
import 'experience_drawer_menu_item.dart';

/// Unified section-switcher drawer (navigation reversal, phase-1-navigation.md).
///
/// Neutral full-height drawer with Guardian and Organisation in the scrollable
/// area and Account bottom-pinned. Profile details live on `/account`, not here.
class ExperienceSectionDrawer extends ConsumerWidget {
  const ExperienceSectionDrawer({super.key});

  String? _activeSemanticKey({
    required String location,
    required AppExperience activeExperience,
  }) {
    if (location == '/account') return 'drawer_account';
    if (activeExperience == AppExperience.guardian) return 'drawer_guardian';
    if (activeExperience == AppExperience.organization) {
      return 'drawer_organisation';
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final activeExperience =
        ref.watch(activeExperienceProvider) ?? AppExperience.guardian;
    final location = GoRouter.maybeOf(context)?.state.uri.path ?? '/';
    final activeKey = _activeSemanticKey(
      location: location,
      activeExperience: activeExperience,
    );
    final topEntries = DrawerMenuConfig.sectionSwitcherEntries(l: l);
    final accountItem = DrawerMenuConfig.accountItem(l);

    return Drawer(
      backgroundColor: AppColorTokens.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('drawer_close'),
                    icon: const Icon(Icons.close),
                    tooltip: l.close,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: AppLogoTitle(
                      title: l.appTitle,
                      experience: activeExperience,
                    ),
                  ),
                ],
              ),
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
            ExperienceDrawerMenuItem(
              key: const Key('drawer_account'),
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
