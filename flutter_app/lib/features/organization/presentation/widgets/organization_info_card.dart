import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization.dart';

class OrganizationInfoCard extends StatelessWidget {
  final Organization org;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final AppLocalizations l;
  final String Function(AppLocalizations, OrganizationType) localizedTypeLabel;

  const OrganizationInfoCard({
    super.key,
    required this.org,
    required this.theme,
    required this.colorScheme,
    required this.l,
    required this.localizedTypeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        label: '${org.name}, ${localizedTypeLabel(l, org.type)}',
        child: Card(
          color: AppTheme.orgBlueDarker,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: org.type == OrganizationType.professional
                          ? AppTheme.orgIconBg
                          : AppTheme.orgCharityBg,
                      child: Icon(
                        org.type == OrganizationType.professional
                            ? Icons.business
                            : Icons.volunteer_activism,
                        size: 32,
                        color: org.type == OrganizationType.professional
                            ? AppTheme.orgIconFg
                            : AppTheme.orgCharityFg,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            org.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: org.type == OrganizationType.professional
                                  ? AppTheme.orgBadgeBg
                                  : AppTheme.orgCharityBadgeBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              localizedTypeLabel(l, org.type),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: org.type == OrganizationType.professional
                                    ? AppTheme.orgBadgeFg
                                    : AppTheme.orgCharityBadgeFg,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (org.bio.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(org.bio, style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  )),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.people,
                      label: l.memberCount(org.memberCount),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: Icons.pets,
                      label: l.petCount(org.petCount),
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _StatChip({required this.icon, required this.label, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: colorScheme.primary),
      label: Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
