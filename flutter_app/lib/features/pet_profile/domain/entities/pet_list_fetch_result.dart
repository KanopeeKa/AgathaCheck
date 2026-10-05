import 'pet.dart';
import 'pet_cache_freshness.dart';

/// Where the pet list payload came from after a [PetRepository.fetchAllPets] call.
enum PetListFetchSource { remote, localCache }

/// Result of loading pets with explicit cache authority metadata (Package 7 / D2).
class PetListFetchResult {
  const PetListFetchResult({
    required this.pets,
    required this.source,
    required this.freshness,
    this.fetchedAt,
  });

  final List<Pet> pets;
  final PetListFetchSource source;
  final PetCacheFreshness freshness;
  final DateTime? fetchedAt;

  bool get isStale => freshness != PetCacheFreshness.fresh;

  bool get isFromRemote =>
      source == PetListFetchSource.remote &&
      freshness == PetCacheFreshness.fresh;
}
