import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/providers/api_base_url_provider.dart';
import '../../../../../core/utils/resolve_static_asset_url.dart';
import '../../../domain/entities/discoverable_organization.dart';
import '../../../domain/entities/organization.dart';
import '../../utils/org_screen_theme.dart';
import '../org_image_avatar.dart';

/// Discover tile — top ~2/3 hero cover, bottom ~1/3 centred logo, name, locality.
class OrgDiscoveryTile extends ConsumerWidget {
  const OrgDiscoveryTile({super.key, required this.organization});

  final DiscoverableOrganization organization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final apiBaseUrl = ref.read(apiBaseUrlProvider);
    final locality = organization.displayLocality.trim();
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
            child: SizedBox(
              height: 240,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: _HeroCover(
                      photoUrl: organization.photoUrl,
                      resolvedPhotoUrl: resolvedPhoto,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (organization.logoUrl.isNotEmpty)
                            OrgLogoImage(
                              logoUrl: organization.logoUrl,
                              resolvedUrl: resolvedLogo,
                              height: 24,
                            )
                          else
                            OrgImageAvatar(
                              imageUrl: organization.photoUrl,
                              type: OrganizationType.charity,
                              radius: 16,
                              resolvedUrl: resolvedPhoto,
                            ),
                          const SizedBox(height: 4),
                          Text(
                            organization.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          if (locality.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              locality,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
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

class _HeroCover extends StatelessWidget {
  const _HeroCover({required this.photoUrl, required this.resolvedPhotoUrl});

  final String photoUrl;
  final String resolvedPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (photoUrl.isEmpty) {
      return ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.volunteer_activism,
            size: 40,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Image.network(
      resolvedPhotoUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 32,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
