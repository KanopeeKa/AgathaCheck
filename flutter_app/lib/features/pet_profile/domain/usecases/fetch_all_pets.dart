import '../entities/pet_list_fetch_result.dart';
import '../repositories/pet_repository.dart';

/// Loads all pets with cache authority metadata for presentation (Package 7).
class FetchAllPets {
  const FetchAllPets(this.repository);

  final PetRepository repository;

  Future<PetListFetchResult> call() => repository.fetchAllPets();
}
