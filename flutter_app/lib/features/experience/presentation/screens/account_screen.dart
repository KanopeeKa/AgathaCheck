import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/dashboard_section.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../config/drawer_menu_config.dart';
import '../widgets/organisation_visibility_section.dart';
import '../widgets/account_organisation_settings_section.dart';
import '../widgets/experience_shell_scaffold.dart';
import '../../domain/entities/app_experience.dart';

/// Account dashboard at `/account` — global personal/app-level utilities.
///
/// Reachable only from the drawer's bottom-pinned Account item (phase-1-navigation.md §9).
/// Contains: My Details, Default experience, Help, About, Contact, Legal, Sign out.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final experience = AppExperience.guardian; // Default fallback for account screen

    return ExperienceShellScaffold(
      experience: experience,
      currentLocation: '/account',
      screenTitle: l.accountTitle,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardSection(
              title: l.accountProfileSection,
              previewBuilder: (context) => _AccountRow(
                key: const Key('account_my_details'),
                icon: Icons.person_outline,
                label: l.myDetails,
                onTap: () => context.push('/my-details'),
              ),
            ),
            DashboardSection(
              title: l.accountPreferencesSection,
              previewBuilder: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  OrganisationVisibilitySection(embedded: true),
                  SizedBox(height: 16),
                  AccountOrganisationSettingsSection(embedded: true),
                ],
              ),
            ),
            DashboardSection(
              title: l.accountSupportSection,
              previewBuilder: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AccountRow(
                    key: const Key('account_help'),
                    icon: Icons.help_outline,
                    label: l.helpTitle,
                    onTap: () => context.push('/help'),
                  ),
                  _AccountRow(
                    key: const Key('account_about'),
                    icon: Icons.info_outline,
                    label: l.aboutUs,
                    onTap: () => context.push('/about'),
                  ),
                  _AccountRow(
                    key: const Key('account_contact'),
                    icon: Icons.email_outlined,
                    label: l.contact,
                    onTap: () => _launchContact(),
                  ),
                  _AccountRow(
                    key: const Key('account_legal'),
                    icon: Icons.gavel_outlined,
                    label: l.legalInformation,
                    onTap: () => context.push('/legal'),
                  ),
                ],
              ),
            ),
            DashboardSection(
              title: l.accountActionsSection,
              accentColor: Theme.of(context).colorScheme.error,
              previewBuilder: (context) => _AccountRow(
                key: const Key('account_sign_out'),
                icon: Icons.logout,
                label: l.logOut,
                isDestructive: true,
                onTap: () => ref.read(authProvider.notifier).logout(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchContact() async {
    final uri = Uri(scheme: 'mailto', path: DrawerMenuConfig.contactEmail);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
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

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(color: color),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

