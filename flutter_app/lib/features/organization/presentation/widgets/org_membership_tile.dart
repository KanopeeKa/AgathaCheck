import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/resolve_static_asset_url.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/presentation/widgets/pet_card.dart';
import '../../domain/entities/organization.dart';
import '../utils/org_screen_theme.dart';
import 'org_image_avatar.dart';

/// My Organisations hub tile — pet-grid geometry (D-v3-TILE-1, D-desk-S2).
///
/// Top ~2/3 cover media, bottom ~1/3 meta. No hero → solid [organizationPrimary].
class OrgMembershipTile extends ConsumerWidget {
  const OrgMembershipTile({
    super.key,
    required this.organization,
    this.onTap,
    required this.tileWidth,
  });

  final Organization organization;
  final VoidCallback? onTap;
  final double tileWidth;

  static double tileHeightFor(double tileWidth) => tileWidth * 1.5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final resolvedPhoto = resolveStaticAssetUrl(
      organization.photoUrl,
      apiBaseUrl: ref.read(apiBaseUrlProvider),
    );
    final resolvedLogo = resolveStaticAssetUrl(
      organization.logoUrl,
      apiBaseUrl: ref.read(apiBaseUrlProvider),
    );
    final tileHeight = tileHeightFor(tileWidth);

    String typeLabel(OrganizationType type) {
      switch (type) {
        case OrganizationType.professional:
          return l.orgTypeProfessional;
        case OrganizationType.charity:
          return l.orgTypeCharity;
      }
    }

    final memberLabel = l.petCount(organization.petCount);

    return MergeSemantics(
      child: Semantics(
        identifier: 'org_membership_${organization.id}',
        button: onTap != null,
        onTap: onTap,
        label:
            '${organization.name}, ${typeLabel(organization.type)}, '
            '$memberLabel',
        child: SizedBox(
          width: tileWidth,
          height: tileHeight,
          child: Card(
            key: Key('org_membership_tile_${organization.id}'),
            color: orgListCardColor(),
            elevation: 0,
            shape: orgListCardTheme().shape,
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.zero,
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: _CoverArea(
                      organization: organization,
                      resolvedPhotoUrl: resolvedPhoto,
                      resolvedLogoUrl: resolvedLogo,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                organization.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 4,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _TypeBadge(
                                    type: organization.type,
                                    label: typeLabel(organization.type),
                                  ),
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
                                    ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.pets,
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

  /// Grid tile width for hub [Wrap] layouts.
  static double tileWidthFor(double maxWidth) => PetCard.tileWidthFor(maxWidth);
}

class _CoverArea extends StatelessWidget {
  const _CoverArea({
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
        if (organization.photoUrl.isEmpty)
          ColoredBox(
            color: AppColorTokens.organizationPrimary,
            child: Center(
              child: Icon(
                organization.type == OrganizationType.professional
                    ? Icons.business
                    : Icons.volunteer_activism,
                size: 36,
                color: AppColorTokens.inverse.withValues(alpha: 0.9),
              ),
            ),
          )
        else
          Image.network(
            resolvedPhotoUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: AppColorTokens.organizationPrimary,
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 28,
                  color: AppColorTokens.inverse.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        if (hasLogo)
          Positioned(
            left: 6,
            bottom: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColorTokens.surface,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: OrgLogoImage(
                  logoUrl: organization.logoUrl,
                  resolvedUrl: resolvedLogoUrl,
                  height: 22,
                ),
              ),
            ),
          ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPro ? AppTheme.orgBadgeBg : AppTheme.orgCharityBadgeBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isPro ? AppTheme.orgBadgeFg : AppTheme.orgCharityBadgeFg,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
