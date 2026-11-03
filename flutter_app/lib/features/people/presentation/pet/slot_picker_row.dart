import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/people_commands.dart';
import '../../application/people_providers.dart';
import '../../domain/enums/contact_group.dart';
import '../../domain/enums/contact_role.dart';
import '../../domain/enums/relationship_kind.dart';
import '../../domain/services/people_query.dart';
import '../labels/people_labels.dart';
import '../picker/people_picker_field.dart';
import '../picker/people_picker_result.dart';
import 'confirm_replace_pet_slot.dart';

/// One vet or emergency slot inside the pet emergency manage sheet.
class SlotPickerRow extends ConsumerWidget {
  const SlotPickerRow({
    super.key,
    required this.petId,
    required this.petName,
    required this.slotKind,
    required this.currentContactId,
    required this.emptyLabel,
    this.allowClear = true,
  });

  final String petId;
  final String petName;
  final RelationshipKind slotKind;
  final String? currentContactId;
  final String emptyLabel;
  final bool allowClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final selected = currentContactId == null
        ? null
        : ref.watch(personSummaryProvider(currentContactId!));

    final query = _queryForSlot(slotKind, currentContactId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            slotKind.label(l),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          PeoplePickerField(
            purpose: 'pet_slot_${slotKind.wireValue}',
            query: query,
            value: selected,
            placeholder: emptyLabel,
            quickAddGroup: ContactGroup.professional,
            onChanged: (PeoplePickerResult? result) async {
              await _onPickerResult(context, ref, result);
            },
          ),
        ],
      ),
    );
  }

  /// Slots are established from the whole directory — a contact need not be
  /// linked to the pet yet (the slot write creates the link).
  PeopleQuery _queryForSlot(RelationshipKind kind, String? currentId) {
    switch (kind) {
      case RelationshipKind.primaryVet:
      case RelationshipKind.outOfHoursVet:
        return PeopleQuery(
          groups: const {ContactGroup.professional},
          roles: const {ContactRole.vet},
          allowNone: allowClear,
          currentId: currentId,
        );
      case RelationshipKind.emergencyContact:
        return PeopleQuery(
          groups: const {ContactGroup.carer},
          allowNone: false,
          currentId: currentId,
        );
      default:
        return PeopleQuery(currentId: currentId);
    }
  }

  Future<void> _onPickerResult(
    BuildContext context,
    WidgetRef ref,
    PeoplePickerResult? result,
  ) async {
    final commands = ref.read(peopleCommandsProvider);

    switch (result) {
      case PeoplePickerContactResult(:final contact):
        if (slotKind == RelationshipKind.emergencyContact) {
          await commands.linkContactToPet(
            contactId: contact.id,
            petId: petId,
            relationshipKind: RelationshipKind.emergencyContact,
          );
          return;
        }
        final ok = await confirmReplacePetSlotIfNeeded(
          context: context,
          ref: ref,
          petId: petId,
          petName: petName,
          slotKind: slotKind,
          incomingContactId: contact.id,
        );
        if (!ok) return;
        await commands.setPetSlot(
          contactId: contact.id,
          petId: petId,
          slotKind: slotKind,
          slotContactId: contact.id,
        );
      case PeoplePickerNoneResult():
        await commands.setPetSlot(
          contactId: currentContactId ?? '',
          petId: petId,
          slotKind: slotKind,
          slotContactId: null,
        );
      case null:
      case PeoplePickerTypedNameResult():
        break;
    }
  }
}
