import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/providers/api_base_url_provider.dart';
import '../../../../../core/utils/resolve_static_asset_url.dart';
import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../auth/presentation/widgets/profile_photo_avatar.dart';
import '../../../domain/entities/admin_contact_self_prefs.dart';
import '../../../domain/entities/org_person.dart';
import '../../../domain/entities/organization_member.dart';
import '../../../domain/services/admin_contacts.dart';
import '../../widgets/organization_role_labels.dart';

class AdminContactCard extends ConsumerWidget {
  const AdminContactCard({
    super.key,
    required this.person,
    required this.orgId,
    required this.viewerRole,
    required this.viewerUserId,
    required this.phoneVisibility,
    this.contactPhone = '',
    this.isSelf = false,
    this.canEditOther = false,
    this.canDeleteOther = false,
    this.onView,
    this.onEdit,
    this.onDelete,
  });

  final OrgPersonSummary person;
  final String orgId;
  final OrgMemberRole? viewerRole;
  final String? viewerUserId;
  final AdminPhoneVisibility phoneVisibility;
  final String contactPhone;
  final bool isSelf;
  final bool canEditOther;
  final bool canDeleteOther;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Future<void> _launchTel(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchMail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final roleLabel = person.role != null
        ? localizedOrgMemberRole(l, person.role!)
        : '';
    final showCall = canViewerCallAdminContact(
      viewerRole: viewerRole,
      contact: person,
      viewerUserId: viewerUserId,
      phoneVisibility: phoneVisibility,
      phone: contactPhone,
    );
    // D-v3-MSG-1: hide message affordance until DEF-MSG (#569).
    const showMessage = false;
    final photoUrl = resolveStaticAssetUrl(
      person.photoUrl ?? '',
      apiBaseUrl: ref.read(apiBaseUrlProvider),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        container: true,
        label: isSelf
            ? l.adminContactsSelfCardSemantics(person.displayName)
            : l.adminContactsCardSemantics(person.displayName, roleLabel),
        child: Material(
          color: isSelf
              ? AppColorTokens.organizationLight
              : colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: person.isPending ? null : onView,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelf
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withAlpha(120),
                  width: isSelf ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfilePhotoAvatar(
                        photoUrl: photoUrl,
                        initials: person.initials,
                        radius: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isSelf)
                              Text(
                                l.adminContactsYourCard,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            Text(
                              person.displayName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (roleLabel.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                roleLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            if (person.isPrimaryContact) ...[
                              const SizedBox(height: 6),
                              _PrimaryBadge(label: l.orgPrimaryContactBadge),
                            ],
                          ],
                        ),
                      ),
                      if (canEditOther || canDeleteOther)
                        PopupMenuButton<String>(
                          key: Key('admin_contact_menu_${person.recordId}'),
                          tooltip: l.adminContactsMoreOptions,
                          onSelected: (action) {
                            switch (action) {
                              case 'edit':
                                onEdit?.call();
                                break;
                              case 'delete':
                                onDelete?.call();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            if (canEditOther)
                              PopupMenuItem(value: 'edit', child: Text(l.edit)),
                            if (canDeleteOther)
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  l.orgRemoveMember,
                                  style: TextStyle(color: colorScheme.error),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  if (showCall || showMessage) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (showCall)
                          _ActionButton(
                            key: Key('admin_contact_call_${person.recordId}'),
                            icon: Icons.phone_outlined,
                            label: l.adminContactsCall,
                            onPressed: () => _launchTel(contactPhone),
                          ),
                        if (showCall && showMessage) const SizedBox(width: 8),
                        if (showMessage)
                          _ActionButton(
                            key: Key(
                              'admin_contact_message_${person.recordId}',
                            ),
                            icon: Icons.message_outlined,
                            label: l.adminContactsMessage,
                            onPressed: () => _launchMail(person.email!),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryBadge extends StatelessWidget {
  const _PrimaryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColorTokens.organizationLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
