import '../entities/vet.dart';
import '../repositories/vet_repository.dart';

class GetAllVets {
  const GetAllVets(this.repository);

  final VetRepository repository;

  Future<List<Vet>> call() {
    return repository.getAllVets();
  }
}
