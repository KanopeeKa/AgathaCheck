import '../entities/vet.dart';
import '../repositories/vet_repository.dart';

class UpdateVet {
  const UpdateVet(this.repository);

  final VetRepository repository;

  Future<Vet> call(Vet vet) {
    return repository.updateVet(vet);
  }
}
