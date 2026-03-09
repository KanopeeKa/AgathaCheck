import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/repositories/pet_repository.dart';

class MockPetRepository extends Mock implements PetRepository {
  static const _fallback = Pet(id: '', name: '', species: '');

  @override
  Future<List<Pet>> getAllPets() => super.noSuchMethod(
        Invocation.method(#getAllPets, []),
        returnValue: Future.value(<Pet>[]),
      ) as Future<List<Pet>>;

  @override
  Future<Pet> addPet(Pet? pet) => super.noSuchMethod(
        Invocation.method(#addPet, [pet]),
        returnValue: Future.value(_fallback),
      ) as Future<Pet>;

  @override
  Future<Pet> updatePet(Pet? pet) => super.noSuchMethod(
        Invocation.method(#updatePet, [pet]),
        returnValue: Future.value(_fallback),
      ) as Future<Pet>;

  @override
  Future<void> deletePet(String? id) => super.noSuchMethod(
        Invocation.method(#deletePet, [id]),
        returnValue: Future.value(),
      ) as Future<void>;
}
