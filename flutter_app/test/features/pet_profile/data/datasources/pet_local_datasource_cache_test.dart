import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_profile_app/features/pet_profile/data/datasources/pet_local_datasource.dart';
import 'package:pet_profile_app/features/pet_profile/data/models/pet_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('clearCache removes pets and lastSyncedAt for user scope', () async {
    final prefs = await SharedPreferences.getInstance();
    final local = PetLocalDataSourceImpl(prefs, userId: 'u1');
    await local.addPet(PetModel(id: 'p1', name: 'Rex', species: 'Dog'));
    await local.setLastSyncedAt(DateTime.utc(2026, 1, 1));

    await local.clearCache();

    expect(await local.getAllPets(), isEmpty);
    expect(await local.getLastSyncedAt(), isNull);
  });
}
