import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/category_badge.dart';
import '../widgets/profile_photo_avatar.dart';

class ProfileHeaderCard extends StatelessWidget {
  final dynamic user;
  final ThemeData theme;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final String Function(String) resolvePhotoUrl;

  const ProfileHeaderCard({
    super.key,
    required this.user,
    required this.theme,
    required this.l10n,
    required this.onEdit,
    required this.resolvePhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        label:
            '${user.displayName}, ${user.email}, ${user.category == 'professional_multi_pet' ? l10n.professionalMultiPet : l10n.petGuardian}',
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      ProfilePhotoAvatar(
                        photoUrl:
                            user.photoUrl != null && user.photoUrl!.isNotEmpty
                            ? resolvePhotoUrl(user.photoUrl!)
                            : null,
                        initials: user.initials ?? '',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.displayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        label: user.category == 'professional_multi_pet'
                            ? l10n.categoryLabel(l10n.professionalMultiPet)
                            : l10n.categoryLabel(l10n.petGuardian),
                        child: CategoryBadge(category: user.category ?? ''),
                      ),
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          user.bio!,
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer.withAlpha(
                            120,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                l10n.detailsVisibleToShared,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    tooltip: l10n.editProfile,
                    icon: const Icon(Icons.edit),
                    onPressed: onEdit,
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
