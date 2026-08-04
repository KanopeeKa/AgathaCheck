import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/utils/resolve_static_asset_url.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization.dart';
import '../providers/organization_providers.dart';
import 'org_image_avatar.dart';
import 'org_presentation/org_profile_hero_layout.dart';

/// Unboxed hero-aligned branding editor (D-v3-EDIT-1).
class OrganizationBrandingSection extends ConsumerWidget {
  const OrganizationBrandingSection({
    super.key,
    required this.org,
    required this.theme,
    required this.colorScheme,
    required this.l,
    required this.nameController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.nameValidator,
  });

  final Organization org;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final AppLocalizations l;
  final TextEditingController nameController;
  final OrganizationType selectedType;
  final ValueChanged<OrganizationType> onTypeChanged;
  final String? Function(String?)? nameValidator;

  String _resolveUrl(WidgetRef ref, String path) {
    return resolveStaticAssetUrl(
      path,
      apiBaseUrl: ref.read(apiBaseUrlProvider),
    );
  }

  String _localizedTypeLabel(OrganizationType type) {
    switch (type) {
      case OrganizationType.professional:
        return l.orgTypeProfessional;
      case OrganizationType.charity:
        return l.orgTypeCharity;
    }
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
        final message = _uploadErrorMessage(e);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  String _uploadErrorMessage(Object error) {
    final raw = error.toString();
    const prefix = 'Exception: ';
    if (raw.startsWith(prefix)) {
      return raw.substring(prefix.length);
    }
    return raw;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedPhoto = _resolveUrl(ref, org.photoUrl);
    final resolvedLogo = _resolveUrl(ref, org.logoUrl);

    return Column(
      key: const Key('org_edit_hero'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OrgProfileHeroLayout.horizontalPadding,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: OrgProfileHeroLayout.coverHeight,
              child: org.photoUrl.isNotEmpty
                  ? Image.network(
                      resolvedPhoto,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _CoverPlaceholder(org: org),
                    )
                  : _CoverPlaceholder(org: org),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            OrgProfileHeroLayout.horizontalPadding,
            8,
            OrgProfileHeroLayout.horizontalPadding,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                key: const Key('org_upload_cover_button'),
                onPressed: () => _pickAndUpload(context, ref, isLogo: false),
                icon: const Icon(Icons.upload, size: 18),
                label: Text(l.orgUploadCover),
              ),
              const SizedBox(height: 4),
              Text(
                l.orgImageHeroGuidance,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -OrgProfileHeroLayout.logoOverlap),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: OrgProfileHeroLayout.horizontalPadding,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    org.logoUrl.isNotEmpty
                        ? OrgLogoImage(
                            logoUrl: org.logoUrl,
                            resolvedUrl: resolvedLogo,
                            height: OrgProfileHeroLayout.logoHeight,
                          )
                        : OrgImageAvatar(
                            imageUrl: org.photoUrl,
                            type: org.type,
                            radius: OrgProfileHeroLayout.logoHeight / 2,
                            resolvedUrl: resolvedPhoto,
                          ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('org_upload_logo_button'),
                      onPressed: () =>
                          _pickAndUpload(context, ref, isLogo: true),
                      icon: const Icon(Icons.upload, size: 18),
                      label: Text(l.orgUploadLogo),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: OrgProfileHeroLayout.logoHeight + 48,
                      child: Text(
                        l.orgImageLogoGuidance,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: OrgProfileHeroLayout.bandGap),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: OrgProfileHeroLayout.logoOverlap,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          key: const Key('org_name_field'),
                          controller: nameController,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          autofillHints: const [AutofillHints.organizationName],
                          validator: nameValidator,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<OrganizationType>(
                          key: const Key('org_type_dropdown'),
                          value: selectedType,
                          decoration: InputDecoration(
                            labelText: l.organizationType,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: OrganizationType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(_localizedTypeLabel(type)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) onTypeChanged(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
