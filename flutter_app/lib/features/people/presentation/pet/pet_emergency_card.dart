import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pet_people.dart';
import '../../domain/enums/relationship_kind.dart';
import '../../domain/services/pet_people_slots.dart';
import '../labels/people_labels.dart';
import 'pet_emergency_manage_sheet.dart';
import 'pet_people_call_action.dart';

class PetEmergencyCard extends ConsumerWidget {
  const PetEmergencyCard({
    super.key,
    required this.people,
    required this.canManage,
  });

  final PetPeople people;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final primary = primaryVetRelationship(people);
    final ooh = outOfHoursVetRelationship(people);
    final emergencies = emergencyContactRelationships(people);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.peoplePetEmergencyCardTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (canManage)
                  TextButton(
                    key: const Key('pet_emergency_manage_button'),
                    onPressed: () => showPetEmergencyManageSheet(
                      context: context,
                      ref: ref,
                      people: people,
                    ),
                    child: Text(l.peoplePetEmergencyManage),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _EmergencyReadRow(
              slotLabel: RelationshipKind.primaryVet.label(l),
              filledName: primary?.contactName,
              emptyLabel: l.peoplePetAddPrimaryVet(people.petName),
              phone: primary?.contactPhone,
              semanticsCallId: 'pet_emergency_call_primary_vet',
            ),
            _EmergencyReadRow(
              slotLabel: RelationshipKind.outOfHoursVet.label(l),
              filledName: ooh?.contactName,
              emptyLabel: l.peoplePetAddOutOfHoursVet(people.petName),
              phone: ooh?.contactPhone,
              semanticsCallId: 'pet_emergency_call_ooh_vet',
            ),
            if (emergencies.isEmpty)
              _EmergencyReadRow(
                slotLabel: l.peopleRelationshipEmergencyContact,
                filledName: null,
                emptyLabel: l.peoplePetAddEmergencyContact,
                phone: null,
              )
            else
              for (final contact in emergencies)
                _EmergencyReadRow(
                  slotLabel: l.peopleRelationshipEmergencyContact,
                  filledName: contact.contactName,
                  emptyLabel: l.peoplePetAddEmergencyContact,
                  phone: contact.contactPhone,
                  semanticsCallId: 'pet_emergency_call_${contact.id}',
                ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyReadRow extends StatelessWidget {
  const _EmergencyReadRow({
    required this.slotLabel,
    required this.filledName,
    required this.emptyLabel,
    required this.phone,
    this.semanticsCallId,
  });

  final String slotLabel;
  final String? filledName;
  final String emptyLabel;
  final String? phone;
  final String? semanticsCallId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasContact = filledName != null && filledName!.trim().isNotEmpty;
    final valueText = hasContact ? filledName! : emptyLabel;
    final valueStyle = hasContact
        ? theme.textTheme.bodyLarge
        : theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slotLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(valueText, style: valueStyle),
              ],
            ),
          ),
          PetPeopleCallAction(
            phone: hasContact ? phone : null,
            semanticsIdentifier: semanticsCallId,
          ),
        ],
      ),
    );
  }
}
