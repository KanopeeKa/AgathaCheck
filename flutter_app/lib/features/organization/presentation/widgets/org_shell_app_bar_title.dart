import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/branding/logo_assets.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/utils/resolve_static_asset_url.dart';
import '../../domain/entities/organization.dart';
import 'org_adaptive_nav_title.dart';
import 'org_image_avatar.dart';

/// Organisation shell app-bar title variants (D-v3-NAV-1).
enum OrgNavTitleVariant {
  /// Agatha logo + title — organisations dashboard only.
  dashboard,

  /// Org thumbnail + adaptive title — in-org deep screens.
  withOrgLogo,

  /// Adaptive title only — org profile (logo in hero).
  textOnly,
}

class OrgShellAppBarTitle extends ConsumerWidget {
  const OrgShellAppBarTitle({
    super.key,
    required this.title,
    required this.variant,
    this.organization,
  });

  final String title;
  final OrgNavTitleVariant variant;
  final Organization? organization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleWidget = Flexible(child: OrgAdaptiveNavTitle(title: title));

    switch (variant) {
      case OrgNavTitleVariant.dashboard:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _agathaLogo(),
            const SizedBox(width: 8),
            titleWidget,
          ],
        );
      case OrgNavTitleVariant.withOrgLogo:
        final org = organization;
        final imageUrl = org?.logoUrl.isNotEmpty == true
            ? org!.logoUrl
            : (org?.photoUrl ?? '');
        final resolvedUrl = imageUrl.isEmpty
            ? null
            : resolveStaticAssetUrl(
                imageUrl,
                apiBaseUrl: ref.read(apiBaseUrlProvider),
              );
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OrgImageAvatar(
              imageUrl: imageUrl,
              type: org?.type ?? OrganizationType.professional,
              radius: 16,
              resolvedUrl: resolvedUrl,
            ),
            const SizedBox(width: 8),
            titleWidget,
          ],
        );
      case OrgNavTitleVariant.textOnly:
        return OrgAdaptiveNavTitle(title: title);
    }
  }

  Widget _agathaLogo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        LogoAssets.pngFor(AppExperience.organization),
        height: 32,
        width: 32,
        fit: BoxFit.cover,
        semanticLabel: 'Agatha Track logo',
      ),
    );
  }
}
