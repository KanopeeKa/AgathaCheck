import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/dashboard_section.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/auth_service.dart';
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
    final experience =
        AppExperience.petCare; // Default fallback for account screen

    return ExperienceShellScaffold(
      experience: experience,
      currentLocation: '/account',
      screenTitle: l.accountTitle,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AccountIdentityLeadIn(
                  user: ref.watch(authProvider).user,
                  title: l.accountTitle,
                  onTap: () => context.push('/my-details'),
                ),
                const SizedBox(height: 24),
                DashboardSection(
                  title: l.accountProfileSection,
                  accentColor: AppColorTokens.operationsGold,
                  previewBuilder: (context) => _AccountRow(
                    key: const Key('account_my_details'),
                    icon: Icons.person_outline,
                    label: l.myDetails,
                    onTap: () => context.push('/my-details'),
                  ),
                ),
                DashboardSection(
                  title: l.accountPreferencesSection,
                  accentColor: AppColorTokens.operationsGold,
                  previewBuilder: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const OrganisationVisibilitySection(embedded: true),
                      const SizedBox(height: 20),
                      Text(
                        l.accountOrgSettingsTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const AccountOrganisationSettingsSection(embedded: true),
                    ],
                  ),
                ),
                DashboardSection(
                  title: l.accountSupportSection,
                  accentColor: AppColorTokens.operationsGold,
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
                const SizedBox(height: 8),
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
        ),
      ),
    );
  }

  Future<void> _launchContact() async {
    final uri = Uri(scheme: 'mailto', path: DrawerMenuConfig.contactEmail);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _AccountIdentityLeadIn extends StatelessWidget {
  const _AccountIdentityLeadIn({
    required this.user,
    required this.title,
    required this.onTap,
  });

  final AuthUser? user;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = user?.firstName?.trim() ?? '';
    final lastName = user?.lastName?.trim() ?? '';
    final email = user?.email.trim() ?? '';
    final name = [
      firstName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ');
    final primaryLine = name.isNotEmpty ? name : email;
    final initials = [
      if (firstName.isNotEmpty) firstName.characters.first,
      if (lastName.isNotEmpty) lastName.characters.first,
    ].join();

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: AppColorTokens.operationsSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: const Key('account_identity_summary'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColorTokens.operationsPaper,
                    foregroundColor: AppColorTokens.operationsOlive,
                    child: Text(
                      initials.isNotEmpty ? initials : title.characters.first,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          primaryLine.isNotEmpty ? primaryLine : title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColorTokens.operationsInk,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email.isNotEmpty ? email : title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
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
          ),
        ),
      ),
    );
  }
}
