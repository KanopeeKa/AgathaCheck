import '../entities/care_establishment.dart';

abstract class CareProgressionRepository {
  Future<List<CareEstablishment>> getEstablishments(String petId);
}
