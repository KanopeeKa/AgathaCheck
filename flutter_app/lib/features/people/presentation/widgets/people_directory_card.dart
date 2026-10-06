import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/contact_summary.dart';
import '../labels/people_labels.dart';
import 'person_card.dart';

/// Directory card aligned with desk styling for People hub lists.
class PeopleDirectoryCard extends StatelessWidget {
  const PeopleDirectoryCard({
    super.key,
    required this.contact,
    required this.onTap,
    this.showChevron = true,
    this.linkedPetCount,
    this.statusLabel,
  });

  final ContactSummary contact;
  final VoidCallback onTap;
  final bool showChevron;
  final int? linkedPetCount;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final roleLine = contact.roles.isEmpty
        ? contact.kind.label(l)
        : contactRolesLine(l, contact.roles);
    final petsLine = linkedPetCount != null && linkedPetCount! > 0
        ? l.peopleDeskLinkedPets(linkedPetCount!)
        : null;

    return PersonCard(
      key: Key('people_directory_card_${contact.id}'),
      contact: contact,
      compact: true,
      roleLine: roleLine,
      petsLine: petsLine,
      contextLine: statusLabel,
      showChevron: showChevron,
      onTap: onTap,
    );
  }
}
