import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/api_base_url_provider.dart';
import '../../../../../core/utils/resolve_static_asset_url.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/organization.dart';
import '../org_image_avatar.dart';

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
    final coverUrl = resolveStaticAssetUrl(org.photoUrl, apiBaseUrl: apiBaseUrl);
    final logoUrl = resolveStaticAssetUrl(org.logoUrl, apiBaseUrl: apiBaseUrl);

    return Semantics(
      label: '${org.name}, $localizedTypeLabel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: org.photoUrl.isNotEmpty
                  ? Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _CoverPlaceholder(org: org),
                    )
                  : _CoverPlaceholder(org: org),
            ),
          ),
          Transform.translate(
            offset: const Offset(16, -32),
            child: Align(
              alignment: Alignment.centerLeft,
              child: org.logoUrl.isNotEmpty
                  ? OrgLogoImage(
                      logoUrl: org.logoUrl,
                      resolvedUrl: logoUrl,
                      height: 64,
                    )
                  : OrgImageAvatar(
                      imageUrl: org.photoUrl,
                      type: org.type,
                      radius: 32,
                      resolvedUrl: coverUrl,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: org.type == OrganizationType.professional
                        ? AppTheme.orgBadgeBg
                        : AppTheme.orgCharityBadgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    localizedTypeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: org.type == OrganizationType.professional
                          ? AppTheme.orgBadgeFg
                          : AppTheme.orgCharityBadgeFg,
                    ),
                  ),
                ),
                if (org.description.isNotEmpty || org.bio.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    org.description.isNotEmpty ? org.description : org.bio,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
