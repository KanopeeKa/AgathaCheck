import '../entities/vet.dart';
import '../repositories/vet_repository.dart';

class CreateVet {
  const CreateVet(this.repository);

  final VetRepository repository;

  Future<Vet> call(Vet vet) {
    return repository.createVet(vet);
  }
}
