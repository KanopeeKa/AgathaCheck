import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/utils/resolve_static_asset_url.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization.dart';
import '../providers/organization_providers.dart';
import 'org_image_avatar.dart';

class OrganizationBrandingSection extends ConsumerWidget {
  const OrganizationBrandingSection({
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

  String _resolveUrl(WidgetRef ref, String path) {
    return resolveStaticAssetUrl(
      path,
      apiBaseUrl: ref.read(apiBaseUrlProvider),
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    WidgetRef ref, {
    required bool isLogo,
  }) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    try {
      final bytes = await picked.readAsBytes();
      final filename = picked.name.isNotEmpty ? picked.name : 'org_image.jpg';
      if (isLogo) {
        await ref
            .read(organizationListProvider.notifier)
            .uploadLogo(org.id, bytes, filename);
      } else {
        await ref
            .read(organizationListProvider.notifier)
            .uploadPhoto(org.id, bytes, filename);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.orgUpdated)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedPhoto = _resolveUrl(ref, org.photoUrl);
    final resolvedLogo = _resolveUrl(ref, org.logoUrl);

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.orgLogo,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OrgLogoImage(
                  logoUrl: org.logoUrl,
                  resolvedUrl: resolvedLogo,
                  height: 48,
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  key: const Key('org_upload_logo_button'),
                  onPressed: () => _pickAndUpload(context, ref, isLogo: true),
                  icon: const Icon(Icons.upload, size: 18),
                  label: Text(l.orgUploadLogo),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l.orgPicture,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OrgImageAvatar(
                  imageUrl: org.photoUrl,
                  type: org.type,
                  radius: 32,
                  resolvedUrl: resolvedPhoto,
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  key: const Key('org_upload_picture_button'),
                  onPressed: () => _pickAndUpload(context, ref, isLogo: false),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: Text(l.orgUploadPicture),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
