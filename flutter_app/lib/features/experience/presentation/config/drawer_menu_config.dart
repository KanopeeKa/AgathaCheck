import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_experience.dart';
import '../../domain/entities/drawer_menu_group.dart';
import '../../domain/entities/drawer_menu_item.dart';

/// Data-driven drawer menu per the navigation reversal (phase-1-navigation.md).
class DrawerMenuConfig {
  const DrawerMenuConfig._();

  static const contactEmail = 'contact@agathatrack.com';

  /// The three section-root paths where the hamburger is shown.
  static const sectionRootPaths = {'/g/home', '/o/orgs', '/account'};

  /// Unified drawer entries: Guardian + Organisation (top), Account (bottom-pinned).
  /// The separator marks the boundary between primary sections and Account.
  static List<DrawerMenuEntry> sectionSwitcherEntries({
    required AppLocalizations l,
    required bool showOrganisationSection,
  }) {
    return [
      DrawerMenuEntry.item(
        DrawerMenuItem(
          semanticKey: 'drawer_guardian',
          label: l.drawerGuardian,
          icon: Icons.pets_outlined,
          group: DrawerMenuGroup.guardianPlum,
          route: AppExperience.guardian.homePath(),
        ),
      ),
      if (showOrganisationSection)
        DrawerMenuEntry.item(
          DrawerMenuItem(
            semanticKey: 'drawer_organisation',
            label: l.drawerOrganisation,
            icon: Icons.business_outlined,
            group: DrawerMenuGroup.organizationGreen,
            route: '/o/orgs',
          ),
        ),
    ];
  }

  /// The bottom-pinned Account item.
  static DrawerMenuItem accountItem(AppLocalizations l) {
    return DrawerMenuItem(
      semanticKey: 'drawer_account',
      label: l.drawerAccount,
      icon: Icons.person_outline,
      group: DrawerMenuGroup.utility,
      route: '/account',
    );
  }
}
