import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../people/domain/entities/people_contact.dart';
import '../../../people/presentation/providers/people_providers.dart';

/// Legacy `vets.id` value stored on [Pet.vetId], with a People roster label.
class PetVetOption {
  const PetVetOption({
    required this.vetId,
    required this.displayName,
    this.phone,
    this.email,
    this.address,
    this.website,
  });

  final String vetId;
  final String displayName;
  final String? phone;
  final String? email;
  final String? address;
  final String? website;
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
        (c) => PetVetOption(
          vetId: c.legacyVetId!,
          displayName: c.name,
          phone: c.phone,
          email: c.email,
          address: c.address,
          website: c.website,
        ),
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
