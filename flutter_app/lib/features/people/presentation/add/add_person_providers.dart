import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pet_profile/pet_profile.dart';

class AddPersonPetOption {
  const AddPersonPetOption({required this.id, required this.name});

  final String id;
  final String name;
}

final addPersonPetsProvider = FutureProvider<List<AddPersonPetOption>>((
  ref,
) async {
  final pets = await ref.watch(allPetsIncludingOrgProvider.future);
  return pets
      .where((p) => p.organizationId == null)
      .map((p) => AddPersonPetOption(id: p.id, name: p.name))
      .toList();
});
