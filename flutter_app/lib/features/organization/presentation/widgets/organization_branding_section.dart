import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/theme/app_color_tokens.dart';
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
    this.uploadsEnabled = true,
  });

  final Organization org;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final AppLocalizations l;
  final TextEditingController nameController;
  final OrganizationType selectedType;
  final ValueChanged<OrganizationType> onTypeChanged;
  final String? Function(String?)? nameValidator;
  final bool uploadsEnabled;

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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  org.photoUrl.isNotEmpty
                      ? Image.network(
                          resolvedPhoto,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _CoverPlaceholder(org: org),
                        )
                      : _CoverPlaceholder(org: org),
                  Positioned(
                    left:
                        OrgProfileHeroLayout.logoHeight +
                        OrgProfileHeroLayout.bandGap,
                    right: OrgProfileHeroLayout.coverGuidanceRightInset,
                    bottom: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          l.orgImageHeroGuidance,
                          key: const Key('org_cover_guidance'),
                          maxLines: 3,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.95),
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: OrgProfileHeroLayout.coverUploadFabInset,
                    bottom: OrgProfileHeroLayout.coverUploadFabInset,
                    child: Semantics(
                      button: true,
                      label: l.orgUploadCover,
                      child: FloatingActionButton.small(
                        key: const Key('org_upload_cover_button'),
                        heroTag: 'org_upload_cover_${org.id}',
                        tooltip: l.orgUploadCover,
                        onPressed: uploadsEnabled
                            ? () => _pickAndUpload(context, ref, isLogo: false)
                            : null,
                        child: const Icon(Icons.camera_alt),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                    Stack(
                      clipBehavior: Clip.none,
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
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Semantics(
                            button: true,
                            label: l.orgUploadLogo,
                            child: FloatingActionButton.small(
                              key: const Key('org_upload_logo_button'),
                              heroTag: 'org_upload_logo_${org.id}',
                              tooltip: l.orgUploadLogo,
                              onPressed: uploadsEnabled
                                  ? () => _pickAndUpload(
                                      context,
                                      ref,
                                      isLogo: true,
                                    )
                                  : null,
                              child: const Icon(Icons.camera_alt),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                        Semantics(
                          identifier: 'org_name_field',
                          textField: true,
                          label: l.organizationName,
                          child: TextFormField(
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
                            autofillHints: const [
                              AutofillHints.organizationName,
                            ],
                            validator: nameValidator,
                            textInputAction: TextInputAction.next,
                          ),
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
    return ColoredBox(
      color: AppColorTokens.organizationPrimary,
      child: Center(
        child: Icon(
          org.type == OrganizationType.professional
              ? Icons.business
              : Icons.volunteer_activism,
          size: 48,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
