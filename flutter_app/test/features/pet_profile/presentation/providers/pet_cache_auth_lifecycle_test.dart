import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/features/auth/data/auth_service.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/pet_profile/data/datasources/pet_local_datasource.dart';
import 'package:pet_profile_app/features/pet_profile/data/models/pet_model.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';

import '../../../../helpers/fakes.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('switching users clears the previous user pet cache', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    container.read(sharedPreferencesProvider);
    container.read(petLocalDataSourceProvider);

    container.read(authProvider.notifier).state = AuthState(
      user: AuthUser(id: 'user-a', email: 'a@test.com'),
      accessToken: 'tok-a',
      refreshToken: 'ref-a',
    );
    container.read(petLocalDataSourceProvider);

    final userADataSource = PetLocalDataSourceImpl(prefs, userId: 'user-a');
    await userADataSource.addPet(
      PetModel(id: 'p1', name: 'Rex', species: 'Dog'),
    );
    await userADataSource.setLastSyncedAt(DateTime.utc(2026, 1, 1));

    container.read(authProvider.notifier).state = AuthState(
      user: AuthUser(id: 'user-b', email: 'b@test.com'),
      accessToken: 'tok-b',
      refreshToken: 'ref-b',
    );
    container.read(petLocalDataSourceProvider);

    expect(await userADataSource.getAllPets(), isEmpty);
    expect(await userADataSource.getLastSyncedAt(), isNull);
  });
}
