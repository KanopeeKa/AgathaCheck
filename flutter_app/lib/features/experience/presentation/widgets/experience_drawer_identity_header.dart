import 'package:flutter/material.dart';

import '../../../../core/branding/logo_assets.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../auth/data/auth_service.dart';
import '../../domain/entities/app_experience.dart';

/// Drawer top block: logo (no link), user name, email.
class ExperienceDrawerIdentityHeader extends StatelessWidget {
  const ExperienceDrawerIdentityHeader({
    super.key,
    required this.user,
    required this.experience,
  });

  final AuthUser? user;
  final AppExperience experience;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final assetPath = LogoAssets.pngForShell(experience);

    final firstName = user?.firstName?.trim() ?? '';
    final lastName = user?.lastName?.trim() ?? '';
    final email = user?.email.trim() ?? '';

    final nameLine1 = firstName.isNotEmpty
        ? firstName
        : (email.isNotEmpty ? email : '—');
    final nameLine2 = lastName.isNotEmpty ? lastName : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              assetPath,
              height: 40,
              width: 40,
              fit: BoxFit.cover,
              semanticLabel: 'AgathaTrack logo',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nameLine1,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColorTokens.heading,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (nameLine2 != null) ...[
            const SizedBox(height: 2),
            Text(
              nameLine2,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColorTokens.heading,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
