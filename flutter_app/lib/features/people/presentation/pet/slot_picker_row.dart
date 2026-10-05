import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/people_commands.dart';
import '../../application/people_providers.dart';
import '../../domain/enums/contact_group.dart';
import '../../domain/enums/contact_role.dart';
import '../../domain/enums/relationship_kind.dart';
import '../../domain/repositories/people_repository.dart';
import '../../domain/services/people_query.dart';
import '../labels/people_labels.dart';
import '../picker/people_picker_field.dart';
import '../picker/people_picker_result.dart';

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

  PeopleQuery _queryForSlot(RelationshipKind kind, String? currentId) {
    switch (kind) {
      case RelationshipKind.primaryVet:
      case RelationshipKind.outOfHoursVet:
        return PeopleQuery(
          groups: const {ContactGroup.professional},
          roles: const {ContactRole.vet},
          allowNone: allowClear,
          currentId: currentId,
          petId: petId,
        );
      case RelationshipKind.emergencyContact:
        return PeopleQuery(
          groups: const {ContactGroup.carer},
          allowNone: false,
          currentId: currentId,
          petId: petId,
        );
      default:
        return PeopleQuery(currentId: currentId, petId: petId);
    }
  }

  Future<void> _onPickerResult(
    BuildContext context,
    WidgetRef ref,
    PeoplePickerResult? result,
  ) async {
    final commands = ref.read(peopleCommandsProvider);
    final l = AppLocalizations.of(context)!;

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
        final ok = await _confirmReplaceSlot(
          context,
          ref,
          l,
          contact.id,
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

  Future<bool> _confirmReplaceSlot(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    String incomingContactId,
  ) async {
    if (slotKind == RelationshipKind.emergencyContact) return true;
    final repo = ref.read(peopleRepositoryProvider);
    final relationships = await repo.fetchPetRelationships(petId);
    final incumbent = relationships
        .where(
          (r) =>
              r.active &&
              r.relationshipKind == slotKind &&
              r.contactId != incomingContactId,
        )
        .firstOrNull;
    if (incumbent == null) return true;
    if (!context.mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.peopleReplaceSlotTitle),
        content: Text(l.peopleReplaceSlotBody(incumbent.contactName, petName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.peopleReplaceSlotConfirm),
          ),
        ],
      ),
    );
    return ok == true;
  }
}
