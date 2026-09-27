import '../entities/household_summary.dart';

abstract class HouseholdRepository {
  Future<List<HouseholdSummary>> listHouseholds(String token);
  Future<HouseholdSummary> createHousehold(
    String name, {
    required String token,
  });
}
