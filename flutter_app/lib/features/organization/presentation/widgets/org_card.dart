import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization.dart';
import '../utils/org_member_count_label.dart';
import 'org_image_avatar.dart';

class OrgCard extends ConsumerWidget {
  const OrgCard({
    super.key,
    required this.organization,
    this.onTap,
  });

  final Organization organization;
  final VoidCallback? onTap;

  String _resolveUrl(WidgetRef ref, String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${ref.read(apiBaseUrlProvider)}$path';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final resolvedPhoto = _resolveUrl(ref, organization.photoUrl);

    String typeLabel(OrganizationType type) {
      switch (type) {
        case OrganizationType.professional:
          return l.orgTypeProfessional;
        case OrganizationType.charity:
          return l.orgTypeCharity;
      }
    }

    final memberLabel = orgMemberCountLabel(
      l,
      organization.memberCount,
      organization.externalCount,
    );

    return MergeSemantics(
      child: Semantics(
        label: '${organization.name}, ${typeLabel(organization.type)}, '
            '$memberLabel, ${l.petCount(organization.petCount)}',
        child: Card(
          key: Key('org_card_${organization.id}'),
          color: AppTheme.orgBlueDarker,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  OrgImageAvatar(
                    imageUrl: organization.photoUrl,
                    type: organization.type,
                    radius: 28,
                    resolvedUrl: resolvedPhoto,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organization.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _TypeBadge(
                                type: organization.type,
                                label: typeLabel(organization.type)),
                            const SizedBox(width: 8),
                            if (organization.isSuperUser)
                              _RoleBadge(
                                label: l.orgSuperAdmin,
                                bg: AppTheme.orgSuperUserBg,
                                fg: AppTheme.orgSuperUserFg,
                                icon: Icons.star,
                              )
                            else if (organization.isOrgAdmin)
                              _RoleBadge(
                                label: l.orgAdmin,
                                bg: AppTheme.orgBadgeBg,
                                fg: AppTheme.orgBadgeFg,
                              )
                            else if (organization.isFoster)
                              _RoleBadge(
                                label: l.orgFoster,
                                bg: AppTheme.orgCharityBadgeBg,
                                fg: AppTheme.orgCharityBadgeFg,
                                icon: Icons.home_work_outlined,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.people_outline,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                memberLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.pets,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              l.petCount(organization.petCount),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ExcludeSemantics(
                    child: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, required this.label});
  final OrganizationType type;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isPro = type == OrganizationType.professional;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPro ? AppTheme.orgBadgeBg : AppTheme.orgCharityBadgeBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isPro ? AppTheme.orgBadgeFg : AppTheme.orgCharityBadgeFg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
