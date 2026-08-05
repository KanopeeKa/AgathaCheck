import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/providers/api_base_url_provider.dart';
import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../core/utils/resolve_static_asset_url.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/presentation/widgets/pet_card.dart';
import '../../../domain/entities/discoverable_organization.dart';
import '../../../domain/entities/organization.dart';
import '../../utils/org_screen_theme.dart';
import '../org_image_avatar.dart';

/// Discover tile — pet-grid sizing, logo over cover, name + two meta lines.
class OrgDiscoveryTile extends ConsumerWidget {
  const OrgDiscoveryTile({super.key, required this.organization});

  final DiscoverableOrganization organization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final apiBaseUrl = ref.read(apiBaseUrlProvider);
    final locality = organization.displayLocality.trim();
    final typeLabel = _localizedTypeLabel(l, organization.type);
    final resolvedPhoto = resolveStaticAssetUrl(
      organization.photoUrl,
      apiBaseUrl: apiBaseUrl,
    );
    final resolvedLogo = resolveStaticAssetUrl(
      organization.logoUrl,
      apiBaseUrl: apiBaseUrl,
    );

    final semanticsParts = <String>[organization.name];
    if (locality.isNotEmpty) semanticsParts.add(locality);
    semanticsParts.add(typeLabel);

    return MergeSemantics(
      child: Semantics(
        identifier: 'org_discovery_${organization.id}',
        button: true,
        label: semanticsParts.join(', '),
        child: Card(
          key: Key('org_discovery_tile_${organization.id}'),
          color: orgListCardColor(),
          elevation: 0,
          shape: orgListCardTheme().shape,
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: () => context.push('/o/orgs/${organization.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _HeroCover(
                        photoUrl: organization.photoUrl,
                        resolvedPhotoUrl: resolvedPhoto,
                        type: organization.type,
                      ),
                      Center(
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
                            child: organization.logoUrl.isNotEmpty
                                ? OrgLogoImage(
                                    logoUrl: organization.logoUrl,
                                    resolvedUrl: resolvedLogo,
                                    height: 32,
                                  )
                                : OrgImageAvatar(
                                    imageUrl: organization.photoUrl,
                                    type: organization.type,
                                    radius: 20,
                                    resolvedUrl: resolvedPhoto,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        if (locality.isNotEmpty)
                          Text(
                            locality,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          typeLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  String _localizedTypeLabel(AppLocalizations l, OrganizationType type) {
    switch (type) {
      case OrganizationType.professional:
        return l.orgTypeProfessional;
      case OrganizationType.charity:
        return l.orgTypeCharity;
    }
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
      return ColoredBox(
        color: AppColorTokens.organizationPrimary,
        child: Center(
          child: Icon(
            type == OrganizationType.professional
                ? Icons.business
                : Icons.volunteer_activism,
            size: 36,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      );
    }
    return Image.network(
      resolvedPhotoUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: AppColorTokens.organizationPrimary,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 28,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
