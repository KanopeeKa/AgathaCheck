import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/pet_profile/data/datasources/pet_local_datasource.dart';
import 'package:pet_profile_app/features/pet_profile/data/models/pet_model.dart';

class MockPetLocalDataSource extends Mock implements PetLocalDataSource {
  static final _fallbackModel = PetModel(
    id: '',
    name: '',
    species: '',
  );

  @override
  Future<PetModel> addPet(PetModel? pet) => super.noSuchMethod(
        Invocation.method(#addPet, [pet]),
        returnValue: Future.value(_fallbackModel),
      ) as Future<PetModel>;

  @override
  Future<PetModel> updatePet(PetModel? pet) => super.noSuchMethod(
        Invocation.method(#updatePet, [pet]),
        returnValue: Future.value(_fallbackModel),
      ) as Future<PetModel>;
}
