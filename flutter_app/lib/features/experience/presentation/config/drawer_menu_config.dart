import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_experience.dart';
import '../../domain/entities/drawer_menu_group.dart';
import '../../domain/entities/drawer_menu_item.dart';

/// Data-driven drawer menu order per [docs/design/navigation-v2.md].
class DrawerMenuConfig {
  const DrawerMenuConfig._();

  static const contactEmail = 'contact@agathatrack.com';

  /// Legacy vet list until phase 10 adds `/g/vets` and `/o/vets`.
  static const legacyVetsPath = '/vets';

  static List<DrawerMenuEntry> guardianEntries({
    required AppLocalizations l,
    required int notificationUnread,
  }) {
    return [
      DrawerMenuEntry.item(
        DrawerMenuItem(
          semanticKey: 'drawer_my_pets',
          label: l.myPets,
          group: DrawerMenuGroup.guardianPlum,
          route: AppExperience.guardian.homePath(),
        ),
      ),
      DrawerMenuEntry.item(
        DrawerMenuItem(
          semanticKey: 'drawer_guardian_notifications',
          label: l.guardianNotificationsDrawer,
          group: DrawerMenuGroup.guardianPlum,
          route: '/g/notifications',
          badgeCount: notificationUnread,
        ),
      ),
      DrawerMenuEntry.item(
        DrawerMenuItem(
          semanticKey: 'drawer_guardian_events',
          label: l.upcomingEvents,
          group: DrawerMenuGroup.guardianPlum,
          route: AppExperience.guardian.eventsPath,
        ),
      ),
      DrawerMenuEntry.item(
        DrawerMenuItem(
          semanticKey: 'drawer_my_vets',
          label: l.myVets,
          group: DrawerMenuGroup.guardianPlum,
          route: legacyVetsPath,
        ),
      ),
      const DrawerMenuEntry.separator(),
      DrawerMenuEntry.item(
        DrawerMenuItem(
          semanticKey: 'drawer_org_view',
          label: l.experienceOrgView,
          group: DrawerMenuGroup.organizationGreen,
          route: '/organizations',
        ),
      ),
      const DrawerMenuEntry.separator(),
      ...utilityEntries(
        l,
        experience: AppExperience.guardian,
        includeInvite: true,
      ),
    ];
  }

  static List<DrawerMenuEntry> organizationEntries({
    required AppLocalizations l,
    required int orgNotificationUnread,
    required bool showGuardianView,
    required bool isFosterPortal,
  }) {
    return [
      DrawerMenuEntry.item(
        DrawerMenuItem(
          semanticKey: 'drawer_my_organisation',
          label: l.myOrganisation,
          group: DrawerMenuGroup.organizationGreen,
          route: AppExperience.organization.homePath(),
        ),
      ),
      DrawerMenuEntry.item(
        DrawerMenuItem(
          semanticKey: 'drawer_org_notifications',
          label: l.orgNotificationsDrawer,
          group: DrawerMenuGroup.organizationGreen,
          route: '/o/notifications',
          badgeCount: orgNotificationUnread,
        ),
      ),
      DrawerMenuEntry.item(
        DrawerMenuItem(
          semanticKey: 'drawer_org_events',
          label: l.upcomingEvents,
          group: DrawerMenuGroup.organizationGreen,
          route: AppExperience.organization.eventsPath,
        ),
      ),
      DrawerMenuEntry.item(
        DrawerMenuItem(
          semanticKey: 'drawer_org_vets',
          label: l.orgVets,
          group: DrawerMenuGroup.organizationGreen,
          route: legacyVetsPath,
        ),
      ),
      if (showGuardianView) ...[
        const DrawerMenuEntry.separator(),
        DrawerMenuEntry.item(
          DrawerMenuItem(
            semanticKey: 'drawer_guardian_view',
            label: l.experienceGuardianView,
            group: DrawerMenuGroup.guardianPlum,
            route: AppExperience.guardian.homePath(),
          ),
        ),
      ],
      const DrawerMenuEntry.separator(),
      ...utilityEntries(
        l,
        experience: AppExperience.organization,
        includeInvite: !isFosterPortal,
      ),
    ];
  }

  static List<DrawerMenuEntry> utilityEntries(
    AppLocalizations l, {
    required AppExperience experience,
    required bool includeInvite,
  }) {
    final settingsPath = experience.settingsPath;
    final invitePath = experience == AppExperience.guardian
        ? '/g/invite'
        : '/o/invite';

    return [
      DrawerMenuEntry.item(
        DrawerMenuItem(
          semanticKey: 'drawer_settings',
          label: l.settings,
          group: DrawerMenuGroup.utility,
          route: settingsPath,
        ),
      ),
      DrawerMenuEntry.item(
        DrawerMenuItem(
          semanticKey: 'drawer_faq',
          label: l.helpTitle,
          group: DrawerMenuGroup.utility,
          route: '/help',
        ),
      ),
      DrawerMenuEntry.item(
        DrawerMenuItem(
          semanticKey: 'drawer_about',
          label: l.aboutUs,
          group: DrawerMenuGroup.utility,
          route: '/about',
        ),
      ),
      DrawerMenuEntry.item(
        DrawerMenuItem(
          semanticKey: 'drawer_contact',
          label: l.contact,
          group: DrawerMenuGroup.utility,
          onTap: () {},
        ),
      ),
      DrawerMenuEntry.item(
        DrawerMenuItem(
          semanticKey: 'drawer_legal',
          label: l.legalInformation,
          group: DrawerMenuGroup.utility,
          route: '/legal',
        ),
      ),
      if (includeInvite) ...[
        const DrawerMenuEntry.separator(),
        DrawerMenuEntry.item(
          DrawerMenuItem(
            semanticKey: 'drawer_invite',
            label: l.invite,
            group: DrawerMenuGroup.utility,
            route: invitePath,
          ),
        ),
      ],
      const DrawerMenuEntry.separator(),
      DrawerMenuEntry.item(
        DrawerMenuItem(
          semanticKey: 'drawer_logout',
          label: l.logOut,
          group: DrawerMenuGroup.utility,
          onTap: () {},
        ),
      ),
    ];
  }
}
