import '../../domain/entities/vet.dart';
import '../../domain/repositories/vet_repository.dart';
import '../datasources/vet_remote_datasource.dart';
import '../models/vet_model.dart';

class VetRepositoryImpl implements VetRepository {
  const VetRepositoryImpl(this.dataSource);

  final VetRemoteDataSource dataSource;

  @override
  Future<List<Vet>> getAllVets() {
    return dataSource.getAllVets();
  }

  @override
  Future<Vet?> getVet(String id) {
    return dataSource.getVet(id);
  }

  @override
  Future<Vet> createVet(Vet vet) {
    return dataSource.createVet(VetModel.fromEntity(vet));
  }

  @override
  Future<Vet> updateVet(Vet vet) {
    return dataSource.updateVet(VetModel.fromEntity(vet));
  }

  @override
  Future<void> deleteVet(String id) {
    return dataSource.deleteVet(id);
  }
}
