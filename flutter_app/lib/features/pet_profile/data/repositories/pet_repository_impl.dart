import '../../domain/entities/pet.dart';
import '../../domain/repositories/pet_repository.dart';
import '../datasources/pet_local_datasource.dart';
import '../models/pet_model.dart';

/// Concrete implementation of [PetRepository].
///
/// Bridges the domain layer with the data layer by converting
/// between [Pet] entities and [PetModel] data objects.
class PetRepositoryImpl implements PetRepository {
  /// Creates a [PetRepositoryImpl] with the given [dataSource].
  PetRepositoryImpl(this.dataSource);

  /// The local data source used for persistence.
  final PetLocalDataSource dataSource;

  @override
  Future<List<Pet>> getAllPets() async {
    final models = await dataSource.getAllPets();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Pet?> getPetById(String id) async {
    final model = await dataSource.getPetById(id);
    return model?.toEntity();
  }

  @override
  Future<Pet> addPet(Pet pet) async {
    final model = PetModel.fromEntity(pet);
    final saved = await dataSource.addPet(model);
    return saved.toEntity();
  }

  @override
  Future<Pet> updatePet(Pet pet) async {
    final model = PetModel.fromEntity(pet);
    final saved = await dataSource.updatePet(model);
    return saved.toEntity();
  }

  @override
  Future<void> deletePet(String id) => dataSource.deletePet(id);
}
