import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/api_base_url_provider.dart';
import '../../../../../core/utils/resolve_static_asset_url.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/discoverable_organization.dart';
import '../../../domain/entities/organization.dart';
import '../../utils/org_screen_theme.dart';
import '../org_image_avatar.dart';

class OrgDiscoveryTile extends ConsumerWidget {
  const OrgDiscoveryTile({super.key, required this.organization});

  final DiscoverableOrganization organization;

  String _locationLabel(AppLocalizations l) {
    final town = organization.town.trim();
    final area = organization.administrativeArea.trim();
    if (town.isNotEmpty && area.isNotEmpty) {
      return l.orgDiscoveryLocation(town, area);
    }
    if (town.isNotEmpty) return town;
    if (area.isNotEmpty) return area;
    return '';
  }

  String _descriptionSnippet(String description) {
    final trimmed = description.trim();
    if (trimmed.length <= 120) return trimmed;
    return '${trimmed.substring(0, 117)}…';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final location = _locationLabel(l);
    final description = _descriptionSnippet(organization.description);
    final resolvedLogo = resolveStaticAssetUrl(
      organization.logoUrl,
      apiBaseUrl: ref.read(apiBaseUrlProvider),
    );

    final semanticsParts = <String>[organization.name];
    if (location.isNotEmpty) semanticsParts.add(location);
    if (description.isNotEmpty) semanticsParts.add(description);

    return MergeSemantics(
      child: Semantics(
        label: semanticsParts.join(', '),
        child: Card(
          key: Key('org_discovery_tile_${organization.id}'),
          color: orgListCardColor(),
          elevation: 0,
          shape: orgListCardTheme().shape,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrgImageAvatar(
                  imageUrl: organization.logoUrl,
                  type: OrganizationType.charity,
                  radius: 28,
                  resolvedUrl: resolvedLogo,
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
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          location,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
