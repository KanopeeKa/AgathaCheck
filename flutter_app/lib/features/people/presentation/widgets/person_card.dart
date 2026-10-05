import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/contact_summary.dart';
import '../hub/hub_highlighted_text.dart';
import '../labels/people_labels.dart';
import 'person_avatar.dart';
import 'person_card_lines.dart';
import 'person_status_chip.dart';

/// Operational row for a contact in lists and pickers.
class PersonCard extends StatelessWidget {
  const PersonCard({
    super.key,
    required this.contact,
    required this.onTap,
    this.compact = false,
    this.roleLine,
    this.petsLine,
    this.contextLine,
    this.statusChipKind,
    this.accessUntil,
    this.showChevron = true,
    this.photoUrl,
    this.highlightQuery,
  });

  final ContactSummary contact;
  final VoidCallback onTap;
  final bool compact;
  final String? roleLine;
  final String? petsLine;
  final String? contextLine;
  final PersonStatusChipKind? statusChipKind;
  final DateTime? accessUntil;
  final bool showChevron;
  final String? photoUrl;
  final String? highlightQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final roles =
        roleLine ??
        (contact.roles.isEmpty ? '' : contactRolesLine(l, contact.roles));
    final pets = petsLine ?? personPetsLine(l, contact.pets);
    final contextText = contextLine ?? personContextLine(contact, l);
    final chipKind =
        statusChipKind ??
        (contact.isInactive ? PersonStatusChipKind.inactive : null);

    final semanticLabel = [
      contact.name,
      if (roles.isNotEmpty) roles,
      if (pets.isNotEmpty) pets,
      if (contextText != null && contextText.isNotEmpty) contextText,
      if (chipKind != null) _chipLabel(l, chipKind),
    ].join(', ');

    return Semantics(
      identifier: 'people_card_${contact.id}',
      button: true,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(bottom: compact ? 4 : 8),
        child: Material(
          color: theme.colorScheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.35)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: compact ? 48 : 56),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  compact ? 6 : 10,
                  10,
                  compact ? 6 : 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    personAvatarFromSummary(
                      contact,
                      size: compact
                          ? PersonAvatarSize.row
                          : PersonAvatarSize.row,
                      photoUrl: photoUrl,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Body(
                        contact: contact,
                        roles: roles,
                        pets: pets,
                        contextText: contextText,
                        compact: compact,
                        highlightQuery: highlightQuery,
                      ),
                    ),
                    if (chipKind != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: PersonStatusChip(
                          kind: chipKind,
                          accessUntil: accessUntil,
                        ),
                      )
                    else if (showChevron)
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _chipLabel(AppLocalizations l, PersonStatusChipKind kind) {
    switch (kind) {
      case PersonStatusChipKind.inactive:
        return l.peopleStatusInactive;
      case PersonStatusChipKind.needsReview:
        return l.peopleStatusNeedsReview;
      case PersonStatusChipKind.invited:
        return l.invited;
      case PersonStatusChipKind.accessUntil:
        return l.peopleAccessUntil('');
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.contact,
    required this.roles,
    required this.pets,
    required this.contextText,
    required this.compact,
    this.highlightQuery,
  });

  final ContactSummary contact;
  final String roles;
  final String pets;
  final String? contextText;
  final bool compact;
  final String? highlightQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HubHighlightedText(
          text: contact.name,
          query: highlightQuery ?? '',
          maxLines: compact ? 1 : 2,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (roles.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            roles,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (!compact && pets.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            pets,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (!compact && contextText != null && contextText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            contextText!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}
