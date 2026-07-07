import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/repositories/pet_repository.dart';
import 'package:pet_profile_app/features/pet_profile/domain/usecases/get_all_pets.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/auth/data/auth_service.dart';
import 'package:pet_profile_app/features/auth/data/token_store.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/app_notification.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/notification_preferences.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/sharing/presentation/providers/sharing_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePetRepository implements PetRepository {
  @override
  Future<List<Pet>> getAllPets() async => <Pet>[];
  @override
  Future<Pet?> getPetById(String id) async => null;
  @override
  Future<Pet> addPet(Pet pet) async => pet;
  @override
  Future<Pet> updatePet(Pet pet) async => pet;
  @override
  Future<void> deletePet(String id) async {}
}

class FakeGetAllPets extends GetAllPets {
  FakeGetAllPets() : super(FakePetRepository());
  @override
  Future<List<Pet>> call() async => <Pet>[];
}

class FakePrefs implements SharedPreferences {
  final Map<String, Object?> _store = {};
  @override
  String? getString(String key) => _store[key] as String?;
  @override
  Future<bool> setString(String key, String value) async {
    _store[key] = value;
    return true;
  }
  @override
  Future<bool> remove(String key) async {
    _store.remove(key);
    return true;
  }
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService implements AuthService {
  @override
  Future<AuthUser> getMe(String accessToken) async => mockUser;
  @override
  Future<String> refreshToken(String refreshToken) async => 'dummy-token';
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier() : super(FakeAuthService(), PrefsTokenStore(FakePrefs())) {
    state = loggedInAuthState;
  }
}

class TestPetListNotifier extends PetListNotifier {
  TestPetListNotifier([List<Pet> initialPets = const []]) : _initialPets = initialPets;
  final List<Pet> _initialPets;

  @override
  Future<List<Pet>> build() async => List<Pet>.from(_initialPets);
  @override
  Future<String> addPet({
    required String name,
    required String species,
    String breed = '',
    DateTime? dateOfBirth,
    double? weight,
    String? gender,
    String bio = '',
    String insurance = '',
    DateTime? neuteredDate,
    bool neuterDismissed = false,
    String chipId = '',
    bool chipDismissed = false,
    String? photoPath,
    String? vetId,
    String? organizationId,
  }) async {
    final pet = Pet(
      id: name.toLowerCase(),
      name: name,
      species: species,
      breed: breed,
      dateOfBirth: dateOfBirth,
      weight: weight,
      gender: gender,
      bio: bio,
      insurance: insurance,
      neuteredDate: neuteredDate,
      neuterDismissed: neuterDismissed,
      chipId: chipId,
      chipDismissed: chipDismissed,
      photoPath: photoPath,
      vetId: vetId,
      colorValue: 0xFF7E57C2,
      organizationId: organizationId,
      passedAway: false,
    );
    state = AsyncValue.data([pet]);
    return pet.id;
  }
}

class FakeHealthEntriesNotifier extends HealthEntriesNotifier {
  @override
  Future<List<HealthEntry>> build() async => [];
}

class FakeNotificationsNotifier extends NotificationsNotifier {
  @override
  Future<List<AppNotification>> build() async => [];

  @override
  Future<void> checkDueEntries() async {}
}

class FakeNotificationPreferencesNotifier extends NotificationPreferencesNotifier {
  @override
  Future<NotificationPreferences> build() async => const NotificationPreferences();
}

class FakePendingSharesNotifier extends PendingSharesNotifier {
  @override
  Future<List<PendingShare>> build() async => [];
}

final mockUser = AuthUser(
  id: 'test-user-id',
  email: 'test@example.com',
  firstName: 'Test',
  lastName: 'User',
);

final loggedInAuthState = AuthState(
  user: mockUser,
  accessToken: 'dummy-token',
  refreshToken: 'dummy-refresh',
  isLoading: false,
  error: null,
);
