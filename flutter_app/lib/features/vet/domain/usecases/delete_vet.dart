import '../repositories/vet_repository.dart';

class DeleteVet {
  const DeleteVet(this.repository);

  final VetRepository repository;

  Future<void> call(String id) {
    return repository.deleteVet(id);
  }
}
