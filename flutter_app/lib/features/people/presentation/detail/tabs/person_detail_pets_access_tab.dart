import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/contact_summary.dart';
import '../../labels/people_labels.dart';
import '../person_detail_target.dart';
import '../widgets/link_pet_sheet.dart';

class PersonDetailPetsAccessTab extends ConsumerWidget {
  const PersonDetailPetsAccessTab({
    super.key,
    required this.contactId,
    required this.pets,
    required this.access,
    required this.rosterPetOptions,
    this.allowLink = true,
  });

  final String contactId;
  final List<ContactPetLink> pets;
  final ContactAccessLine? access;
  final List<RosterPetOption> rosterPetOptions;
  final bool allowLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pets.isEmpty)
          Text(
            l.peopleNoLinkedPets,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final pet in pets)
            _PetAccessRow(pet: pet, access: access, l: l),
        if (allowLink) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('people_detail_link_to_pet'),
            onPressed: () => showLinkPetSheet(
              context: context,
              ref: ref,
              contactId: contactId,
              pets: rosterPetOptions,
            ),
            icon: const Icon(Icons.link),
            label: Text(l.peopleDetailLinkToPet),
          ),
        ],
      ],
    );
  }
}

class _PetAccessRow extends StatelessWidget {
  const _PetAccessRow({
    required this.pet,
    required this.access,
    required this.l,
  });

  final ContactPetLink pet;
  final ContactAccessLine? access;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rel = pet.relationshipKind.label(l);
    final accessLine = _accessLabel(l, access);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(child: Text(pet.petName.isNotEmpty ? pet.petName[0] : '?')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.petName, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    Chip(
                      label: Text(rel),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (accessLine != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    accessLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _accessLabel(AppLocalizations l, ContactAccessLine? access) {
    if (access == null) return null;
    final role = access.role.toLowerCase();
    if (role.contains('co_parent') || role.contains('co-parent')) {
      return l.peopleDetailAccessCoParent;
    }
    if (access.expiresAt != null) {
      final date = formatCalendarDateMedium(access.expiresAt!);
      return '${l.peopleDetailAccessCanLogCare} ${l.peopleAccessUntil(date)}';
    }
    if (role.contains('log')) return l.peopleDetailAccessCanLogCare;
    return access.role;
  }
}
