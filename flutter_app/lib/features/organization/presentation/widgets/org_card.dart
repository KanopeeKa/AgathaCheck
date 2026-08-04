import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/resolve_static_asset_url.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization.dart';
import '../utils/org_member_count_label.dart';
import '../utils/org_screen_theme.dart';
import 'org_image_avatar.dart';

/// My Organisations membership tile — pet-style hero + meta (D-v3-TILE-1).
class OrgCard extends ConsumerWidget {
  const OrgCard({super.key, required this.organization, this.onTap});

  final Organization organization;
  final VoidCallback? onTap;

  static const double tileHeight = 240;

  String _resolveUrl(WidgetRef ref, String path) {
    return resolveStaticAssetUrl(
      path,
      apiBaseUrl: ref.read(apiBaseUrlProvider),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final resolvedPhoto = _resolveUrl(ref, organization.photoUrl);
    final resolvedLogo = _resolveUrl(ref, organization.logoUrl);

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
        identifier: 'org_membership_${organization.id}',
        button: onTap != null,
        onTap: onTap,
        label:
            '${organization.name}, ${typeLabel(organization.type)}, '
            '$memberLabel, ${l.petCount(organization.petCount)}',
        child: Card(
          key: Key('org_card_${organization.id}'),
          color: orgListCardColor(),
          elevation: 0,
          shape: orgListCardTheme().shape,
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: tileHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: _MembershipHero(
                      organization: organization,
                      resolvedPhotoUrl: resolvedPhoto,
                      resolvedLogoUrl: resolvedLogo,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            organization.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _TypeBadge(
                                type: organization.type,
                                label: typeLabel(organization.type),
                              ),
                              const SizedBox(width: 6),
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
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  memberLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.pets,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
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

class _MembershipHero extends StatelessWidget {
  const _MembershipHero({
    required this.organization,
    required this.resolvedPhotoUrl,
    required this.resolvedLogoUrl,
  });

  final Organization organization;
  final String resolvedPhotoUrl;
  final String resolvedLogoUrl;

  @override
  Widget build(BuildContext context) {
    final hasLogo = organization.logoUrl.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        _HeroCover(
          photoUrl: organization.photoUrl,
          resolvedPhotoUrl: resolvedPhotoUrl,
          type: organization.type,
        ),
        if (hasLogo)
          Positioned(
            left: 12,
            bottom: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColorTokens.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: OrgLogoImage(
                  logoUrl: organization.logoUrl,
                  resolvedUrl: resolvedLogoUrl,
                  height: 28,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroCover extends StatelessWidget {
  const _HeroCover({
    required this.photoUrl,
    required this.resolvedPhotoUrl,
    required this.type,
  });

  final String photoUrl;
  final String resolvedPhotoUrl;
  final OrganizationType type;

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isEmpty) {
      return const ColoredBox(color: AppColorTokens.organizationLight);
    }

    return Image.network(
      resolvedPhotoUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const ColoredBox(color: AppColorTokens.organizationLight),
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
