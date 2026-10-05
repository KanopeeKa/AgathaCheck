import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/contact_detail.dart';
import '../../domain/entities/contact_summary.dart';
import '../../domain/entities/household.dart';
import '../../domain/enums/contact_kind.dart';
import '../../domain/enums/contact_role.dart';
import '../../domain/enums/contact_status.dart';
import '../labels/people_labels.dart';
import '../widgets/person_avatar.dart';
import '../widgets/person_status_chip.dart';
import '../widgets/role_chips.dart';

class PersonDetailHeader extends StatelessWidget {
  const PersonDetailHeader({
    super.key,
    required this.name,
    required this.stableId,
    this.kind = ContactKind.person,
    this.subtitle,
    this.roles = const [],
    this.statusChip,
    this.linkedAccount = false,
    this.tierLine,
    this.photoUrl,
  });

  factory PersonDetailHeader.fromSummary(
    AppLocalizations l,
    ContactSummary summary, {
    String? photoUrl,
  }) {
    return PersonDetailHeader(
      name: summary.name,
      stableId: summary.id,
      kind: summary.kind,
      subtitle: _subtitleForSummary(l, summary),
      roles: summary.roles,
      statusChip: _chipForSummary(summary),
      linkedAccount: summary.linkedUserId != null,
      photoUrl: photoUrl,
    );
  }

  factory PersonDetailHeader.fromDetail(
    AppLocalizations l,
    ContactDetail detail,
  ) {
    return PersonDetailHeader(
      name: detail.name,
      stableId: detail.id,
      kind: detail.kind,
      subtitle: _subtitleForDetail(l, detail),
      roles: detail.roles,
      statusChip: detail.status == ContactStatus.inactive
          ? PersonStatusChipKind.inactive
          : null,
      linkedAccount: detail.linkedAccount != null,
      photoUrl: detail.linkedAccount?.photoUrl,
    );
  }

  factory PersonDetailHeader.forHouseholdMember(
    AppLocalizations l, {
    required HouseholdMember member,
    ContactSummary? contact,
  }) {
    final tierLine = member.isOrganiser
        ? l.householdOrganiserLabel
        : l.householdCanLogCareLabel;
    return PersonDetailHeader(
      name: contact?.name ?? member.displayName,
      stableId: contact?.id ?? member.userId,
      kind: contact?.kind ?? ContactKind.person,
      roles: contact?.roles ?? const [],
      tierLine: member.isYou ? '$tierLine · ${l.peopleMemberYou}' : tierLine,
      linkedAccount: contact?.linkedUserId != null,
    );
  }

  final String name;
  final String stableId;
  final ContactKind kind;
  final String? subtitle;
  final List<ContactRole> roles;
  final PersonStatusChipKind? statusChip;
  final bool linkedAccount;
  final String? tierLine;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonAvatar(
          name: name,
          stableId: stableId,
          kind: kind,
          photoUrl: photoUrl,
          size: PersonAvatarSize.header,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (tierLine != null) ...[
                const SizedBox(height: 4),
                Text(
                  tierLine!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (roles.isNotEmpty) ...[
                const SizedBox(height: 8),
                RoleChips(roles: roles),
              ],
              if (statusChip != null) ...[
                const SizedBox(height: 8),
                PersonStatusChip(kind: statusChip!),
              ],
              if (linkedAccount) ...[
                const SizedBox(height: 8),
                Semantics(
                  label: l.peopleDetailLinkedAccount,
                  child: Chip(
                    avatar: const Icon(Icons.verified_user_outlined, size: 16),
                    label: Text(l.peopleDetailLinkedAccount),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String? _subtitleForSummary(
    AppLocalizations l,
    ContactSummary summary,
  ) {
    if (summary.kind == ContactKind.organisation) {
      final roles = contactRolesLine(l, summary.roles);
      return roles.isEmpty
          ? summary.kind.label(l)
          : '${summary.kind.label(l)} · $roles';
    }
    final worksAt = summary.worksAt?.name;
    if (worksAt != null && worksAt.isNotEmpty) {
      return l.peopleWorksAtLine(worksAt);
    }
    return null;
  }

  static String? _subtitleForDetail(AppLocalizations l, ContactDetail detail) {
    if (detail.kind == ContactKind.organisation) {
      final roles = contactRolesLine(l, detail.roles);
      return roles.isEmpty
          ? detail.kind.label(l)
          : '${detail.kind.label(l)} · $roles';
    }
    final worksAt = detail.worksAt?.name;
    if (worksAt != null && worksAt.isNotEmpty) {
      return l.peopleWorksAtLine(worksAt);
    }
    return null;
  }

  static PersonStatusChipKind? _chipForSummary(ContactSummary summary) {
    if (summary.isInactive) return PersonStatusChipKind.inactive;
    final access = summary.access;
    if (access?.expiresAt != null) {
      return PersonStatusChipKind.accessUntil;
    }
    return null;
  }
}
