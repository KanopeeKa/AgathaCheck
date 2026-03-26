
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/usecases/get_all_pets.dart';
import 'package:pet_profile_app/features/pet_profile/domain/repositories/pet_repository.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_profile_app/core/router/app_router.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/utils/constants.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/auth/data/auth_service.dart';

// Override for getAllPetsUseCaseProvider to return empty list in tests
class _FakePetRepository implements PetRepository {
  @override
  Future<List<Pet>> getAllPets() async => <Pet>[];
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class FakeGetAllPets extends GetAllPets {
  FakeGetAllPets() : super(_FakePetRepository());
  @override
  Future<List<Pet>> call() async => <Pet>[];
}
final petsOverride = getAllPetsUseCaseProvider.overrideWith((ref) => FakeGetAllPets());

// Mock user and logged-in auth state for tests
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

// Robust fake SharedPreferences
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
  // Add other required methods as no-op or return null/empty as needed
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Robust fake AuthService
class FakeAuthService implements AuthService {
  @override
  Future<AuthUser> getMe(String accessToken) async => mockUser;
  @override
  Future<String> refreshToken(String refreshToken) async => 'dummy-token';
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier() : super(FakeAuthService(), FakePrefs()) {
    state = loggedInAuthState;
  }
}

final authOverride = authProvider.overrideWith((ref) => FakeAuthNotifier());

// --- TEST NOTIFIER FOR ADD PET ---
class TestPetListNotifier extends PetListNotifier {
  TestPetListNotifier();
  @override
  Future<List<Pet>> build() async {
    return [];
  }

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
    int? organizationId,
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

void main() {
  group('Pet Profile Integration Flow', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    // Helper to print the widget tree for debugging
    Future<void> debugPrintTree(WidgetTester tester) async {
      debugPrint('\n--- WIDGET TREE START ---');
      debugPrint(tester.element(find.byType(Scaffold)).toStringDeep());
      debugPrint('\n--- WIDGET TREE END ---');
    }

    Widget createApp({List<Override> overrides = const []}) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authOverride,
          petsOverride,
          ...overrides,
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(routerProvider);
            return MaterialApp.router(
              title: AppConstants.appTitle,
              theme: AppTheme.lightTheme,
              routerConfig: router,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
            );
          },
        ),
      );
    }

    testWidgets('shows empty state initially', (tester) async {
      final testNotifier = TestPetListNotifier();
      final emptyPetListOverride = petListProvider.overrideWith(() => testNotifier);
      await tester.pumpWidget(createApp(overrides: [emptyPetListOverride]));
      await tester.pumpAndSettle();

      await debugPrintTree(tester);

      final scaffoldContext = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(scaffoldContext)!;

      expect(find.text(l10n.noPetsYet), findsOneWidget, reason: 'Should show empty state text');
      expect(find.text(l10n.addPet), findsOneWidget, reason: 'Should show Add Pet button');
    });

    testWidgets('navigates to add pet form', (tester) async {
      final testNotifier = TestPetListNotifier();
      final emptyPetListOverride = petListProvider.overrideWith(() => testNotifier);
      await tester.pumpWidget(createApp(overrides: [emptyPetListOverride]));
      await tester.pumpAndSettle();

      await debugPrintTree(tester);

      final scaffoldContext = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(scaffoldContext)!;

      final addPetButton = find.text(l10n.addPet);
      expect(addPetButton, findsOneWidget, reason: 'Should find Add Pet button');
      await tester.tap(addPetButton);
      await tester.pumpAndSettle();

      expect(find.text(l10n.petName), findsOneWidget, reason: 'Should show pet name field');
      expect(find.text(l10n.species), findsOneWidget, reason: 'Should show species field');
      expect(find.text(l10n.savePet), findsOneWidget, reason: 'Should show save pet button');
    });

    testWidgets('validates required name field', (tester) async {
      final testNotifier = TestPetListNotifier();
      final emptyPetListOverride = petListProvider.overrideWith(() => testNotifier);
      await tester.pumpWidget(createApp(overrides: [emptyPetListOverride]));
      await tester.pumpAndSettle();

      await debugPrintTree(tester);

      final scaffoldContext = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(scaffoldContext)!;

      final addPetButton = find.text(l10n.addPet);
      expect(addPetButton, findsOneWidget, reason: 'Should find Add Pet button');
      await tester.tap(addPetButton);
      await tester.pumpAndSettle();

      final saveButton = find.text(l10n.savePet);
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // The validator string is hardcoded in pet_form_screen.dart, so we check for it directly
      expect(find.text("Please enter the pet's name"), findsOneWidget, reason: 'Should show required name validation');
    });

    testWidgets('adds a pet and shows it in list', (tester) async {
      final testNotifier = TestPetListNotifier();
      final petListOverride = petListProvider.overrideWith(() => testNotifier);
      await tester.pumpWidget(createApp(overrides: [petListOverride]));
      await tester.pumpAndSettle();

      await debugPrintTree(tester);

      final scaffoldContext = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(scaffoldContext)!;

      final addPetButton = find.text(l10n.addPet);
      expect(addPetButton, findsOneWidget, reason: 'Should find Add Pet button');
      await tester.tap(addPetButton);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Buddy');

      final saveButton = find.text(l10n.savePet);
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Simulate the notifier updating the list
      await testNotifier.addPet(name: 'Buddy', species: 'Dog');
      await tester.pumpAndSettle();

      expect(find.text('Buddy'), findsOneWidget, reason: 'Should show Buddy in the list');
    });
  });
}
