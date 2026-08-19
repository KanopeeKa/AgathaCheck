import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/app_experience.dart';
import '../config/drawer_menu_config.dart';
import '../providers/experience_providers.dart';
import '../utils/drawer_menu_actions.dart';
import 'experience_drawer_identity_header.dart';
import 'experience_drawer_menu.dart';
import 'experience_drawer_menu_item.dart';

/// Unified section-switcher drawer with user identity header.
///
/// Top block: logo (no home link), user name, email, Account.
/// Scrollable: Guardian + Organisation section switchers.
class ExperienceSectionDrawer extends ConsumerWidget {
  const ExperienceSectionDrawer({super.key});

  String? _activeSemanticKey({required String location}) {
    if (location == '/account') return 'drawer_account';
    if (location.startsWith('/g/')) return 'drawer_guardian';
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
        : AppExperience.guardian;
    final activeKey = _activeSemanticKey(location: location);
    final showOrganisationSection = ref.watch(showOrganisationSectionProvider);
    final topEntries = DrawerMenuConfig.sectionSwitcherEntries(
      l: l,
      showOrganisationSection: showOrganisationSection,
    );
    final accountItem = DrawerMenuConfig.accountItem(l);

    return Drawer(
      backgroundColor: AppColorTokens.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  key: const Key('drawer_close'),
                  icon: const Icon(Icons.close),
                  tooltip: l.close,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            ExperienceDrawerIdentityHeader(
              user: auth.user,
              experience: activeExperience,
            ),
            ExperienceDrawerMenuItem(
              key: const Key('drawer_account'),
              item: accountItem,
              isActive: activeKey == 'drawer_account',
              onTap: () =>
                  handleExperienceDrawerItemTap(context, ref, accountItem),
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
          ],
        ),
      ),
    );
  }
}
