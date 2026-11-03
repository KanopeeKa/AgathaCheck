import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../add/add_person_providers.dart';
import 'person_detail_target.dart';

/// Pets a contact can be linked to: the same personal pets Add person offers,
/// with real names — independent of which contacts are already linked.
final linkablePetOptionsProvider = FutureProvider<List<RosterPetOption>>((
  ref,
) async {
  final pets = await ref.watch(addPersonPetsProvider.future);
  return pets
      .map((p) => RosterPetOption(petId: p.id, petName: p.name))
      .toList();
});
