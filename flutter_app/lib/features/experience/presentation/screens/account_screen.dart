import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../config/drawer_menu_config.dart';
import '../widgets/experience_settings_section.dart';
import '../widgets/experience_section_drawer.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../notifications/presentation/widgets/notification_panel.dart';

/// Account dashboard at `/account` — global personal/app-level utilities.
///
/// Reachable only from the drawer's bottom-pinned Account item (phase-1-navigation.md §9).
/// Contains: My Details, Default experience, Help, About, Contact, Legal, Sign out.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final combinedUnread = ref.watch(combinedUnreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l.accountTitle),
        leading: Builder(
          builder: (ctx) => IconButton(
            key: const Key('account_hamburger'),
            icon: const Icon(Icons.menu),
            tooltip: l.sectionDrawerTooltip,
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              key: const Key('experience_notification_bell'),
              icon: Badge(
                isLabelVisible: combinedUnread > 0,
                label: Text('$combinedUnread'),
                child: const Icon(Icons.notifications_outlined),
              ),
              tooltip: l.notificationsBellTooltip,
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      drawer: const ExperienceSectionDrawer(),
      endDrawer: const NotificationPanel(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AccountSection(
            children: [
              _AccountTile(
                key: const Key('account_my_details'),
                icon: Icons.person_outline,
                label: l.myDetails,
                onTap: () => context.push('/my-details'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: const ExperienceSettingsSection(),
            ),
          ),
          const SizedBox(height: 16),
          _AccountSection(
            children: [
              _AccountTile(
                key: const Key('account_help'),
                icon: Icons.help_outline,
                label: l.helpTitle,
                onTap: () => context.push('/help'),
              ),
              _AccountTile(
                key: const Key('account_about'),
                icon: Icons.info_outline,
                label: l.aboutUs,
                onTap: () => context.push('/about'),
              ),
              _AccountTile(
                key: const Key('account_contact'),
                icon: Icons.email_outlined,
                label: l.contact,
                onTap: () => _launchContact(),
              ),
              _AccountTile(
                key: const Key('account_legal'),
                icon: Icons.gavel_outlined,
                label: l.legalInformation,
                onTap: () => context.push('/legal'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AccountSection(
            children: [
              _AccountTile(
                key: const Key('account_sign_out'),
                icon: Icons.logout,
                label: l.logOut,
                isDestructive: true,
                onTap: () => ref.read(authProvider.notifier).logout(),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _launchContact() async {
    final uri = Uri(scheme: 'mailto', path: DrawerMenuConfig.contactEmail);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(children: children),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : null;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: color != null ? TextStyle(color: color) : null),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
