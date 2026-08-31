import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vet.dart';
import '../utils/vet_accent.dart';
import 'care_team_identity_avatar.dart';

/// Warm identity header for a care team / veterinary clinic.
class CareTeamIdentityCard extends StatelessWidget {
  const CareTeamIdentityCard({
    super.key,
    required this.vet,
    required this.accent,
    required this.onEdit,
  });

  final Vet vet;
  final VetAccent accent;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final town = vetTownLabel(vet.address);
    final showFullAddress =
        vet.address.trim().isNotEmpty &&
        vet.address.trim() != town &&
        vet.address.contains(',');

    return Card(
      color: accent.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CareTeamIdentityAvatar(name: vet.name, accent: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vet.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.careTeamClinicType,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  key: const Key('care_team_options_button'),
                  tooltip: l.careTeamOptions,
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      key: const Key('care_team_edit_menu_item'),
                      value: 'edit',
                      child: Text(l.editCareTeam),
                    ),
                  ],
                ),
              ],
            ),
            if (showFullAddress) ...[
              const SizedBox(height: 12),
              _ContactLine(
                icon: Icons.location_on_outlined,
                label: vet.address.trim(),
                semanticsLabel: vet.address.trim(),
              ),
            ] else if (town.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ContactLine(
                icon: Icons.location_on_outlined,
                label: town,
                semanticsLabel: town,
              ),
            ],
            if (vet.phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ContactLine(
                key: const Key('vet_call_link'),
                icon: Icons.phone_outlined,
                label: vet.phone,
                semanticsLabel: '${l.adminContactsCall} ${vet.phone}',
                onTap: () => _launchTel(context, vet.phone, l),
              ),
            ],
            if (vet.email.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ContactLine(
                key: const Key('vet_email_link'),
                icon: Icons.email_outlined,
                label: vet.email,
                semanticsLabel: '${l.vetEmail} ${vet.email}',
                onTap: () => _launchMail(context, vet.email, l),
              ),
            ],
            if (vet.website.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ContactLine(
                icon: Icons.language,
                label: vet.website,
                semanticsLabel: vet.website,
                onTap: () => _launchWeb(context, vet.website, l),
              ),
            ],
            if (vet.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                vet.notes,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _launchTel(
    BuildContext context,
    String phone,
    AppLocalizations l,
  ) async {
    await _launch(context, Uri(scheme: 'tel', path: phone), l);
  }

  Future<void> _launchMail(
    BuildContext context,
    String email,
    AppLocalizations l,
  ) async {
    await _launch(context, Uri(scheme: 'mailto', path: email), l);
  }

  Future<void> _launchWeb(
    BuildContext context,
    String website,
    AppLocalizations l,
  ) async {
    final uri = website.startsWith('http')
        ? Uri.parse(website)
        : Uri.parse('https://$website');
    await _launch(context, uri, l);
  }

  Future<void> _launch(
    BuildContext context,
    Uri uri,
    AppLocalizations l,
  ) async {
    bool canLaunch = false;
    try {
      canLaunch = await canLaunchUrl(uri);
    } catch (_) {
      canLaunch = false;
    }

    if (!canLaunch) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_launchFailedMessage(uri.scheme, l))),
        );
      }
      return;
    }

    try {
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_launchFailedMessage(uri.scheme, l))),
        );
      }
    }
  }

  String _launchFailedMessage(String scheme, AppLocalizations l) {
    final action = switch (scheme) {
      'tel' => l.adminContactsCall,
      'mailto' => l.vetEmail,
      _ => l.website,
    };
    return '$action · ${l.retry}';
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String semanticsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onTap != null ? theme.colorScheme.primary : null,
              decoration: onTap != null ? TextDecoration.underline : null,
              decorationColor: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );

    if (onTap == null) return content;

    return Semantics(
      button: true,
      label: semanticsLabel,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: content,
        ),
      ),
    );
  }
}
