import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/vet/domain/entities/vet.dart';
import 'package:pet_profile_app/features/vet/domain/repositories/vet_repository.dart';

class MockVetRepository extends Mock implements VetRepository {
  static final _fallback = Vet(id: '', name: '');

  @override
  Future<List<Vet>> getAllVets() => super.noSuchMethod(
        Invocation.method(#getAllVets, []),
        returnValue: Future.value(<Vet>[]),
      ) as Future<List<Vet>>;

  @override
  Future<Vet> createVet(Vet? vet) => super.noSuchMethod(
        Invocation.method(#createVet, [vet]),
        returnValue: Future.value(_fallback),
      ) as Future<Vet>;

  @override
  Future<Vet> updateVet(Vet? vet) => super.noSuchMethod(
        Invocation.method(#updateVet, [vet]),
        returnValue: Future.value(_fallback),
      ) as Future<Vet>;

  @override
  Future<void> deleteVet(String? id) => super.noSuchMethod(
        Invocation.method(#deleteVet, [id]),
        returnValue: Future.value(),
      ) as Future<void>;
}
