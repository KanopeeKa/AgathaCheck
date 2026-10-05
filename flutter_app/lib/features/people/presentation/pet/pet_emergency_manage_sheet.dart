import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/people_commands.dart';
import '../../domain/entities/pet_people.dart';
import '../../domain/enums/relationship_kind.dart';
import '../../domain/services/pet_people_slots.dart';
import '../labels/people_labels.dart';
import 'slot_picker_row.dart';

Future<void> showPetEmergencyManageSheet({
  required BuildContext context,
  required WidgetRef ref,
  required PetPeople people,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => PetEmergencyManageSheet(people: people),
  );
}

class PetEmergencyManageSheet extends ConsumerWidget {
  const PetEmergencyManageSheet({super.key, required this.people});

  final PetPeople people;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final primary = primaryVetRelationship(people);
    final ooh = outOfHoursVetRelationship(people);
    final emergencies = emergencyContactRelationships(people);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.peoplePetEmergencyManageTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              SlotPickerRow(
                petId: people.petId,
                petName: people.petName,
                slotKind: RelationshipKind.primaryVet,
                currentContactId: primary?.contactId,
                emptyLabel: l.peoplePetAddPrimaryVet(people.petName),
              ),
              SlotPickerRow(
                petId: people.petId,
                petName: people.petName,
                slotKind: RelationshipKind.outOfHoursVet,
                currentContactId: ooh?.contactId,
                emptyLabel: l.peoplePetAddOutOfHoursVet(people.petName),
              ),
              Text(
                l.peopleRelationshipEmergencyContact,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SlotPickerRow(
                petId: people.petId,
                petName: people.petName,
                slotKind: RelationshipKind.emergencyContact,
                currentContactId: null,
                emptyLabel: l.peoplePetAddEmergencyContact,
                allowClear: false,
              ),
              for (var i = 0; i < emergencies.length; i++)
                _EmergencyManageRow(
                  relationship: emergencies[i],
                  petId: people.petId,
                  canMoveUp: i > 0,
                  canMoveDown: i < emergencies.length - 1,
                  onMove: (delta) => _moveEmergency(
                    ref,
                    emergencies,
                    i,
                    delta,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _moveEmergency(
    WidgetRef ref,
    List<PetRelationship> emergencies,
    int index,
    int delta,
  ) async {
    final nextIndex = index + delta;
    if (nextIndex < 0 || nextIndex >= emergencies.length) return;
    final ordered = List<String>.from(emergencies.map((e) => e.id));
    final item = ordered.removeAt(index);
    ordered.insert(nextIndex, item);
    final contactId = emergencies[index].contactId;
    await ref.read(peopleCommandsProvider).reorderEmergencyContacts(
      contactId: contactId,
      petId: people.petId,
      orderedRelationshipIds: ordered,
    );
  }
}

class _EmergencyManageRow extends ConsumerWidget {
  const _EmergencyManageRow({
    required this.relationship,
    required this.petId,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMove,
  });

  final PetRelationship relationship;
  final String petId;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(relationship.contactName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: Key('pet_emergency_up_${relationship.id}'),
            tooltip: l.peopleReorderUp,
            onPressed: canMoveUp ? () => onMove(-1) : null,
            icon: const Icon(Icons.arrow_upward),
          ),
          IconButton(
            key: Key('pet_emergency_down_${relationship.id}'),
            tooltip: l.peopleReorderDown,
            onPressed: canMoveDown ? () => onMove(1) : null,
            icon: const Icon(Icons.arrow_downward),
          ),
          IconButton(
            key: Key('pet_emergency_remove_${relationship.id}'),
            tooltip: l.delete,
            onPressed: () async {
              await ref.read(peopleCommandsProvider).removePetRelationship(
                contactId: relationship.contactId,
                petId: petId,
                relationshipId: relationship.id,
              );
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
