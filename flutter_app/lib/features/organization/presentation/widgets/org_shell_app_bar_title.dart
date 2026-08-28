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
    switch (variant) {
      case OrgNavTitleVariant.dashboard:
        return _logoTitleRow(
          context: context,
          leadingWidth: 32,
          leading: _agathaLogo(),
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
        return _logoTitleRow(
          context: context,
          leadingWidth: 32,
          leading: OrgImageAvatar(
            imageUrl: imageUrl,
            type: org?.type ?? OrganizationType.professional,
            radius: 16,
            resolvedUrl: resolvedUrl,
          ),
        );
      case OrgNavTitleVariant.textOnly:
        return OrgAdaptiveNavTitle(title: title);
    }
  }

  Widget _logoTitleRow({
    required BuildContext context,
    required double leadingWidth,
    required Widget leading,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxTitleWidth = constraints.hasBoundedWidth
            ? (constraints.maxWidth - leadingWidth - 8)
                .clamp(0.0, double.infinity)
            : MediaQuery.sizeOf(context).width * 0.55;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxTitleWidth),
              child: OrgAdaptiveNavTitle(title: title),
            ),
          ],
        );
      },
    );
  }

  Widget _agathaLogo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        LogoAssets.pngFor(AppExperience.organization),
        height: 32,
        width: 32,
        fit: BoxFit.cover,
        semanticLabel: 'AgathaTrack logo',
      ),
    );
  }
}
