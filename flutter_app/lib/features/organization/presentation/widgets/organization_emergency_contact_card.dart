import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/utils/resolve_static_asset_url.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/profile_photo_avatar.dart';
import '../../domain/entities/organization.dart';

class OrganizationEmergencyContactCard extends ConsumerWidget {
  const OrganizationEmergencyContactCard({
    super.key,
    required this.org,
    required this.theme,
    required this.colorScheme,
    required this.l,
  });

  final Organization org;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final AppLocalizations l;

  String _resolvePhotoUrl(WidgetRef ref, String? path) {
    return resolveStaticAssetUrl(
      path ?? '',
      apiBaseUrl: ref.read(apiBaseUrlProvider),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contact = org.primaryContact;
    if (contact == null) return const SizedBox.shrink();

    final initials = contact.displayName.trim().isNotEmpty
        ? contact.displayName
              .trim()
              .split(RegExp(r'\s+'))
              .map((p) => p.isNotEmpty ? p[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    return Card(
      color: AppTheme.orgBlueDarker,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.orgEmergencyContactTitle(org.name),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfilePhotoAvatar(
                  photoUrl: _resolvePhotoUrl(ref, contact.photoUrl),
                  initials: initials,
                  radius: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.orgSuperUserBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l.orgPrimaryContact,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.orgSuperUserFg,
                          ),
                        ),
                      ),
                      if (contact.email != null &&
                          contact.email!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                contact.email!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (contact.phone.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                contact.phone,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
