import '../entities/vet.dart';

abstract class VetRepository {
  Future<List<Vet>> getAllVets();
  Future<Vet?> getVet(String id);
  Future<Vet> createVet(Vet vet);
  Future<Vet> updateVet(Vet vet);
  Future<void> deleteVet(String id);
}
