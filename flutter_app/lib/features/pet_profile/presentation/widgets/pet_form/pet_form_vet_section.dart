import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../people/people.dart';

class PetFormVetSection extends ConsumerWidget {
  const PetFormVetSection({
    super.key,
    required this.selectedPrimaryVetContactId,
    required this.onPrimaryVetContactIdChanged,
  });

  final String? selectedPrimaryVetContactId;
  final ValueChanged<String?> onPrimaryVetContactIdChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = selectedPrimaryVetContactId == null
        ? null
        : ref.watch(personSummaryProvider(selectedPrimaryVetContactId!));

    return PeoplePickerField(
      purpose: 'pet_primary_vet',
      query: PeopleQuery(
        groups: const {ContactGroup.professional},
        roles: const {ContactRole.vet},
        allowNone: true,
        currentId: selectedPrimaryVetContactId,
      ),
      value: selected,
      quickAddGroup: ContactGroup.professional,
      onChanged: (PeoplePickerResult? result) {
        switch (result) {
          case PeoplePickerContactResult(:final contact):
            onPrimaryVetContactIdChanged(contact.id);
          case PeoplePickerNoneResult():
            onPrimaryVetContactIdChanged(null);
          case null:
          case PeoplePickerTypedNameResult():
            break;
        }
      },
    );
  }
}
