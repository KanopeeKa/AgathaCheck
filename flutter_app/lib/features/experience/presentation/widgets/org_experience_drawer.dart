import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../organization/presentation/providers/organization_providers.dart';
import '../../domain/entities/app_experience.dart';
import '../../domain/services/org_onboarding_rules.dart';
import '../providers/experience_providers.dart';

/// Organisation experience hamburger menu.
class OrgExperienceDrawer extends ConsumerWidget {
  const OrgExperienceDrawer({
    super.key,
    required this.showGuardianView,
    required this.isFosterPortal,
  });

  final bool showGuardianView;
  final bool isFosterPortal;

  static const _supportEmail = 'contact@agathatrack.com';

  Future<void> _openContactEmail() async {
    final uri = Uri(scheme: 'mailto', path: _supportEmail);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final orgsAsync = ref.watch(organizationListProvider);
    final orgUnread = ref.watch(orgUnreadNotificationCountProvider);
    final guardianUnread = ref.watch(guardianUnreadNotificationCountProvider);

    return Drawer(
      child: SafeArea(
        child: orgsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (orgs) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
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
                if (orgs.isEmpty)
                  ListTile(
                    key: const Key('drawer_create_org'),
                    leading: const Icon(Icons.add_business_outlined),
                    title: Text(l.drawerCreateOrg),
                    onTap: () {
                      Navigator.pop(context);
                      context.go(OrgOnboardingRules.onboardingPath);
                    },
                  )
                else
                  ...orgs.map(
                    (org) => ListTile(
                      key: Key('drawer_org_${org.id}'),
                      leading: const Icon(Icons.business_outlined),
                      title: Text(org.name),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/organizations/${org.id}');
                      },
                    ),
                  ),
                ListTile(
                  key: const Key('drawer_org_notifications'),
                  leading: Badge(
                    isLabelVisible: orgUnread > 0,
                    label: Text('$orgUnread'),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  title: Text(l.orgNotificationsDrawer),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/o/notifications');
                  },
                ),
                ListTile(
                  key: const Key('drawer_org_events'),
                  leading: const Icon(Icons.event_outlined),
                  title: Text(l.upcomingEvents),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(AppExperience.organization.eventsPath);
                  },
                ),
                const Divider(),
                if (showGuardianView)
                  ListTile(
                    key: const Key('drawer_my_pets'),
                    leading: Badge(
                      isLabelVisible: guardianUnread > 0,
                      label: Text('$guardianUnread'),
                      child: const Icon(Icons.pets_outlined),
                    ),
                    title: Text(l.myPets),
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(activeExperienceProvider.notifier).state =
                          AppExperience.guardian;
                      context.go(AppExperience.guardian.homePath());
                    },
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(l.settings),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppExperience.organization.settingsPath);
                  },
                ),
                ListTile(
                  key: const Key('drawer_faq'),
                  leading: const Icon(Icons.help_outline),
                  title: Text(l.helpTitle),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/help');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l.aboutUs),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/about');
                  },
                ),
                ListTile(
                  key: const Key('drawer_contact'),
                  leading: const Icon(Icons.mail_outline),
                  title: Text(l.contact),
                  onTap: () async {
                    Navigator.pop(context);
                    await _openContactEmail();
                  },
                ),
                ListTile(
                  key: const Key('drawer_legal'),
                  leading: const Icon(Icons.gavel_outlined),
                  title: Text(l.legalInformation),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/legal');
                  },
                ),
                if (!isFosterPortal) ...[
                  const Divider(),
                  ListTile(
                    key: const Key('drawer_invite'),
                    leading: const Icon(Icons.person_add_outlined),
                    title: Text(l.invite),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/o/invite');
                    },
                  ),
                ],
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(l.logOut),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(authProvider.notifier).logout();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
