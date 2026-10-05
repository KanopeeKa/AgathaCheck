import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../people/people.dart';
import '../../../../../l10n/app_localizations.dart';

class PetDetailPrimaryVetField extends ConsumerWidget {
  const PetDetailPrimaryVetField({
    super.key,
    required this.petId,
    required this.currentContactId,
  });

  final String petId;
  final String? currentContactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final selected = currentContactId == null
        ? null
        : ref.watch(personSummaryProvider(currentContactId!));

    return Row(
      children: [
        Icon(
          Icons.local_hospital,
          size: 16,
          color: selected != null
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: PeoplePickerField(
            purpose: 'pet_detail_primary_vet',
            query: PeopleQuery(
              groups: const {ContactGroup.professional},
              roles: const {ContactRole.vet},
              allowNone: true,
              currentId: currentContactId,
            ),
            value: selected,
            placeholder: l.noVetAssigned,
            quickAddGroup: ContactGroup.professional,
            onChanged: (PeoplePickerResult? result) async {
              final commands = ref.read(peopleCommandsProvider);
              switch (result) {
                case PeoplePickerContactResult(:final contact):
                  await commands.setPetSlot(
                    contactId: contact.id,
                    petId: petId,
                    slotKind: RelationshipKind.primaryVet,
                    slotContactId: contact.id,
                  );
                case PeoplePickerNoneResult():
                  await commands.setPetSlot(
                    contactId: currentContactId ?? '',
                    petId: petId,
                    slotKind: RelationshipKind.primaryVet,
                    slotContactId: null,
                  );
                case null:
                case PeoplePickerTypedNameResult():
                  break;
              }
            },
          ),
        ),
      ],
    );
  }
}
