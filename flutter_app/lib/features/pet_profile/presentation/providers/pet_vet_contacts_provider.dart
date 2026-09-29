import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../people/domain/entities/people_contact.dart';
import '../../../people/presentation/providers/people_providers.dart';

/// Legacy `vets.id` value stored on [Pet.vetId], with a People roster label.
class PetVetOption {
  const PetVetOption({required this.vetId, required this.displayName});

  final String vetId;
  final String displayName;
}

List<PetVetOption> petVetOptionsFromContacts(List<PeopleContact> contacts) {
  final options = contacts
      .where(
        (c) =>
            c.inactiveAt == null &&
            c.roles.contains('vet') &&
            c.legacyVetId != null &&
            c.legacyVetId!.isNotEmpty,
      )
      .map(
        (c) => PetVetOption(vetId: c.legacyVetId!, displayName: c.name),
      )
      .toList();
  options.sort((a, b) => a.displayName.compareTo(b.displayName));
  return options;
}

final petVetOptionsProvider = Provider<AsyncValue<List<PetVetOption>>>((ref) {
  final contactsAsync = ref.watch(peopleContactsProvider);
  return contactsAsync.whenData(petVetOptionsFromContacts);
});

PetVetOption? findPetVetOption(List<PetVetOption> options, String? vetId) {
  if (vetId == null || vetId.isEmpty) return null;
  return options.where((o) => o.vetId == vetId).firstOrNull;
}
