import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/vet/data/datasources/vet_remote_datasource.dart';
import 'package:pet_profile_app/features/vet/data/models/vet_model.dart';

class MockVetRemoteDataSource extends Mock implements VetRemoteDataSource {
  static final _fallbackModel = VetModel(
    id: '',
    name: '',
  );

  @override
  Future<List<VetModel>> getAllVets() => super.noSuchMethod(
        Invocation.method(#getAllVets, []),
        returnValue: Future.value(<VetModel>[]),
      ) as Future<List<VetModel>>;

  @override
  Future<VetModel?> getVet(String? id) => super.noSuchMethod(
        Invocation.method(#getVet, [id]),
        returnValue: Future.value(null),
        returnValueForMissingStub: Future.value(null),
      ) as Future<VetModel?>;

  @override
  Future<VetModel> createVet(VetModel? vet) => super.noSuchMethod(
        Invocation.method(#createVet, [vet]),
        returnValue: Future.value(_fallbackModel),
      ) as Future<VetModel>;

  @override
  Future<VetModel> updateVet(VetModel? vet) => super.noSuchMethod(
        Invocation.method(#updateVet, [vet]),
        returnValue: Future.value(_fallbackModel),
      ) as Future<VetModel>;

  @override
  Future<void> deleteVet(String? id) => super.noSuchMethod(
        Invocation.method(#deleteVet, [id]),
        returnValue: Future.value(),
      ) as Future<void>;
}
