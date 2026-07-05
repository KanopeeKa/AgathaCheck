import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization.dart';
import '../utils/org_member_count_label.dart';
import 'org_image_avatar.dart';

class OrganizationInfoCard extends ConsumerWidget {
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

  String _resolveUrl(WidgetRef ref, String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${ref.read(apiBaseUrlProvider)}$path';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedPhoto = _resolveUrl(ref, org.photoUrl);
    final resolvedLogo = _resolveUrl(ref, org.logoUrl);

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
                if (org.logoUrl.isNotEmpty) ...[
                  OrgLogoImage(
                    logoUrl: org.logoUrl,
                    resolvedUrl: resolvedLogo,
                    height: 64,
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    OrgImageAvatar(
                      imageUrl: org.photoUrl,
                      type: org.type,
                      radius: 32,
                      resolvedUrl: resolvedPhoto,
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
                  Text(
                    org.bio,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.people,
                      label: orgMemberCountLabel(
                          l, org.memberCount, org.externalCount),
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

  const _StatChip(
      {required this.icon, required this.label, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Chip(
        avatar: Icon(icon, size: 18, color: colorScheme.primary),
        label: Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
