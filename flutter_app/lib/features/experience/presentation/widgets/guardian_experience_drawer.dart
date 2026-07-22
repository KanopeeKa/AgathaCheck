import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../domain/entities/app_experience.dart';
import '../../domain/services/org_onboarding_rules.dart';
import '../providers/experience_providers.dart';

/// Guardian experience hamburger menu.
class GuardianExperienceDrawer extends ConsumerWidget {
  const GuardianExperienceDrawer({
    super.key,
    required this.unreadCount,
    required this.showOrgView,
  });

  final int unreadCount;
  final bool showOrgView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);

    return Drawer(
      child: SafeArea(
        child: ListView(
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
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(l.settings),
              onTap: () {
                Navigator.pop(context);
                context.push(AppExperience.guardian.settingsPath);
              },
            ),
            ListTile(
              leading: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(Icons.notifications_outlined),
              ),
              title: Text(l.notifications),
              onTap: () {
                Navigator.pop(context);
                context.push('/g/notifications');
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(l.upcomingEvents),
              onTap: () {
                Navigator.pop(context);
                context.go(AppExperience.guardian.eventsPath);
              },
            ),
            ListTile(
              key: const Key('drawer_invite'),
              leading: const Icon(Icons.person_add_outlined),
              title: Text(l.invite),
              onTap: () {
                Navigator.pop(context);
                context.push('/g/invite');
              },
            ),
            const Divider(),
            ListTile(
              key: const Key('drawer_create_organisation'),
              leading: const Icon(Icons.add_business_outlined),
              title: Text(l.createOrJoinOrganization),
              onTap: () {
                Navigator.pop(context);
                ref.read(activeExperienceProvider.notifier).state =
                    AppExperience.organization;
                context.go(OrgOnboardingRules.onboardingPath);
              },
            ),
            if (showOrgView)
              ListTile(
                key: const Key('drawer_org_view'),
                leading: const Icon(Icons.business_outlined),
                title: Text(l.experienceOrgView),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(activeExperienceProvider.notifier).state =
                      AppExperience.organization;
                  context.go(AppExperience.organization.homePath());
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
              leading: const Icon(Icons.mail_outline),
              title: Text(l.contact),
              onTap: () {
                Navigator.pop(context);
                context.push('/help');
              },
            ),
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
        ),
      ),
    );
  }
}
