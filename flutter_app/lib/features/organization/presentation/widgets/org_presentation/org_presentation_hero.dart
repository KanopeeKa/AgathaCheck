import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/api_base_url_provider.dart';
import '../../../../../core/utils/resolve_static_asset_url.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/organization.dart';
import '../org_image_avatar.dart';
import 'org_profile_hero_layout.dart';

class OrgPresentationHero extends ConsumerWidget {
  const OrgPresentationHero({
    super.key,
    required this.org,
    required this.localizedTypeLabel,
  });

  final Organization org;
  final String localizedTypeLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final apiBaseUrl = ref.watch(apiBaseUrlProvider);
    final coverUrl = resolveStaticAssetUrl(
      org.photoUrl,
      apiBaseUrl: apiBaseUrl,
    );
    final logoUrl = resolveStaticAssetUrl(org.logoUrl, apiBaseUrl: apiBaseUrl);

    final summaryText = org.description.isNotEmpty ? org.description : org.bio;
    final semanticsLabel = summaryText.isNotEmpty
        ? '${org.name}, $localizedTypeLabel, $summaryText'
        : '${org.name}, $localizedTypeLabel';

    return Semantics(
      label: semanticsLabel,
      child: Column(
        key: const Key('org_presentation_hero'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: OrgProfileHeroLayout.horizontalPadding,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: OrgProfileHeroLayout.coverHeight,
                child: org.photoUrl.isNotEmpty
                    ? Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _CoverPlaceholder(org: org),
                      )
                    : _CoverPlaceholder(org: org),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -OrgProfileHeroLayout.logoOverlap),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: OrgProfileHeroLayout.horizontalPadding,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroLogo(org: org, coverUrl: coverUrl, logoUrl: logoUrl),
                  const SizedBox(width: OrgProfileHeroLayout.bandGap),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: OrgProfileHeroLayout.logoOverlap,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            org.name,
                            key: const Key('org_hero_name'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _TypeBadge(type: org.type, label: localizedTypeLabel),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (org.description.isNotEmpty || org.bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                OrgProfileHeroLayout.horizontalPadding,
                0,
                OrgProfileHeroLayout.horizontalPadding,
                8,
              ),
              child: Text(
                org.description.isNotEmpty ? org.description : org.bio,
                key: const Key('org_hero_description'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroLogo extends StatelessWidget {
  const _HeroLogo({
    required this.org,
    required this.coverUrl,
    required this.logoUrl,
  });

  final Organization org;
  final String coverUrl;
  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    return org.logoUrl.isNotEmpty
        ? OrgLogoImage(
            key: const Key('org_hero_logo'),
            logoUrl: org.logoUrl,
            resolvedUrl: logoUrl,
            height: OrgProfileHeroLayout.logoHeight,
          )
        : OrgImageAvatar(
            key: const Key('org_hero_logo'),
            imageUrl: org.photoUrl,
            type: org.type,
            radius: OrgProfileHeroLayout.logoHeight / 2,
            resolvedUrl: coverUrl,
          );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, required this.label});

  final OrganizationType type;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('org_hero_type'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: type == OrganizationType.professional
            ? AppTheme.orgBadgeBg
            : AppTheme.orgCharityBadgeBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: type == OrganizationType.professional
              ? AppTheme.orgBadgeFg
              : AppTheme.orgCharityBadgeFg,
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.org});

  final Organization org;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          org.type == OrganizationType.professional
              ? Icons.business
              : Icons.volunteer_activism,
          size: 48,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
