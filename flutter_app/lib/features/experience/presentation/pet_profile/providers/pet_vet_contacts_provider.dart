import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/people/people.dart';

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

List<PetVetOption> petVetOptionsFromRoster(Roster? roster) {
  if (roster == null) return const [];
  final options = <PetVetOption>[];
  for (final contact in roster.contacts) {
    if (contact.isInactive) continue;
    if (!contact.roles.contains(ContactRole.vet)) continue;
    final vetId = contact.linkedVetRecordId;
    if (vetId == null || vetId.isEmpty) continue;
    options.add(PetVetOption(vetId: vetId, displayName: contact.name));
  }
  options.sort((a, b) => a.displayName.compareTo(b.displayName));
  return options;
}

final petVetOptionsProvider = Provider<AsyncValue<List<PetVetOption>>>((ref) {
  return ref.watch(rosterProvider).whenData(petVetOptionsFromRoster);
});

PetVetOption? findPetVetOption(List<PetVetOption> options, String? vetId) {
  if (vetId == null || vetId.isEmpty) return null;
  return options.where((o) => o.vetId == vetId).firstOrNull;
}
