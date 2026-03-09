import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/vet/data/datasources/vet_remote_datasource.dart';
import 'package:pet_profile_app/features/vet/data/models/vet_model.dart';

class MockVetRemoteDataSource extends Mock implements VetRemoteDataSource {
  static final _fallbackModel = VetModel(
    id: '',
    name: '',
  );

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
}
