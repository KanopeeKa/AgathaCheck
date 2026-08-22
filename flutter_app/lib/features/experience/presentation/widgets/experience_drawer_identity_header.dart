import 'package:flutter/material.dart';

import '../../../../core/branding/logo_assets.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../auth/data/auth_service.dart';
import '../../domain/entities/app_experience.dart';
import '../../domain/entities/drawer_menu_item.dart';

/// Compact, non-navigable drawer brand treatment.
class ExperienceDrawerBrandHeader extends StatelessWidget {
  const ExperienceDrawerBrandHeader({
    super.key,
    required this.experience,
    required this.brandLabel,
    required this.logoLabel,
    required this.closeTooltip,
    required this.onClose,
  });

  final AppExperience experience;
  final String brandLabel;
  final String logoLabel;
  final String closeTooltip;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assetPath = LogoAssets.pngForShell(experience);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              assetPath,
              height: 36,
              width: 36,
              fit: BoxFit.cover,
              semanticLabel: logoLabel,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              brandLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColorTokens.heading,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            key: const Key('drawer_close'),
            icon: const Icon(Icons.close),
            tooltip: closeTooltip,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// Bottom-pinned global Account destination with quiet user identity context.
class ExperienceDrawerIdentityHeader extends StatelessWidget {
  const ExperienceDrawerIdentityHeader({
    super.key,
    required this.user,
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final AuthUser? user;
  final DrawerMenuItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = user?.firstName?.trim() ?? '';
    final lastName = user?.lastName?.trim() ?? '';
    final email = user?.email.trim() ?? '';
    final displayName = [
      firstName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ');
    final primaryLine = displayName.isNotEmpty
        ? displayName
        : (email.isNotEmpty ? email : item.label);
    final secondaryLine = displayName.isNotEmpty && email.isNotEmpty
        ? email
        : item.label;
    final initials = [
      if (firstName.isNotEmpty) firstName.characters.first,
      if (lastName.isNotEmpty) lastName.characters.first,
    ].join();
    final accent = isActive
        ? AppColorTokens.operationsOlive
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      child: Material(
        color: isActive ? AppColorTokens.surfaceAlt : Colors.transparent,
        child: InkWell(
          key: const Key('drawer_account'),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Row(
              children: [
                if (isActive)
                  Container(
                    width: 3,
                    height: 72,
                    color: AppColorTokens.operationsOlive,
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: AppColorTokens.operationsPaper,
                          foregroundColor: accent,
                          child: Text(
                            initials.isNotEmpty ? initials : item.label[0],
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                primaryLine,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppColorTokens.heading,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                secondaryLine,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurfaceVariant,
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
}
