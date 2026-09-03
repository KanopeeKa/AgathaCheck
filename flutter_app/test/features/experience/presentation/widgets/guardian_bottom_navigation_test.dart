import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/experience_shell_scaffold.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_bottom_navigation.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/fakes.dart';

class _EmptyOrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => [];
}

Widget _buildCompactShell({
  required SharedPreferences prefs,
  required String currentLocation,
  required Size viewport,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      experienceEligibilityProvider.overrideWith(
        (ref) => AsyncValue.data(
          ExperienceEligibilityRules.compute(
            pets: const [Pet(id: '1', name: 'A', species: 'Cat')],
            orgMembershipCount: 0,
          ),
        ),
      ),
      combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
      guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
      orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      organizationListProvider.overrideWith(_EmptyOrgListNotifier.new),
    ],
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(size: viewport),
        child: ExperienceShellScaffold(
          experience: AppExperience.petCare,
          currentLocation: currentLocation,
          child: const Center(child: Text('Today content')),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('GuardianBottomNavigation', () {
    test('maps each primary destination to its selected tab', () {
      expect(GuardianBottomNavigation.indexFor('/pc/home'), 0);
      expect(GuardianBottomNavigation.indexFor('/pc/pets'), 1);
      expect(GuardianBottomNavigation.indexFor('/pc/events'), 2);
      expect(GuardianBottomNavigation.indexFor('/pc/fostering'), 3);
      expect(GuardianBottomNavigation.indexFor('/account'), 4);
    });

    test('maps nested Guardian workspace routes to the closest tab', () {
      expect(GuardianBottomNavigation.indexFor('/pc/vets'), 0);
      expect(GuardianBottomNavigation.indexFor('/pc/vets/vet-1'), 0);
      expect(GuardianBottomNavigation.indexFor('/pet/pet-1'), 1);
      expect(GuardianBottomNavigation.indexFor('/pet/pet-1/timeline'), 1);
      expect(GuardianBottomNavigation.indexFor('/pet/pet-1/weight'), 1);
      expect(GuardianBottomNavigation.indexFor('/pet/pet-1/health-issues'), 1);
      expect(GuardianBottomNavigation.indexFor('/pet/pet-1/events'), 2);
      expect(GuardianBottomNavigation.indexFor('/pet/pet-1/events/entry-1'), 2);
      expect(GuardianBottomNavigation.indexFor('/add'), 1);
      expect(GuardianBottomNavigation.indexFor('/account/orgs/org-1'), 4);
    });

    test('recognises Guardian workspace routes', () {
      expect(GuardianBottomNavigation.supports('/pc/home'), isTrue);
      expect(GuardianBottomNavigation.supports('/pc/pets'), isTrue);
      expect(GuardianBottomNavigation.supports('/pc/events'), isTrue);
      expect(GuardianBottomNavigation.supports('/pc/fostering'), isTrue);
      expect(GuardianBottomNavigation.supports('/account'), isTrue);
      expect(GuardianBottomNavigation.supports('/pc/vets/vet-1'), isTrue);
      expect(GuardianBottomNavigation.supports('/pet/pet-1'), isTrue);
      expect(GuardianBottomNavigation.supports('/pc/onboarding'), isFalse);
      expect(GuardianBottomNavigation.supports('/o/orgs'), isFalse);
    });

    test('only uses the mobile bar below the compact breakpoint', () {
      expect(GuardianBottomNavigation.isCompact(599), isTrue);
      expect(GuardianBottomNavigation.isCompact(600), isFalse);
      expect(GuardianBottomNavigation.isCompact(1280), isFalse);
    });
  });

  group('GuardianBottomNavigation widget', () {
    testWidgets('renders tab labels for primary destinations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            bottomNavigationBar: const GuardianBottomNavigation(
              currentLocation: '/pc/home',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Pets'), findsOneWidget);
      expect(find.text('Actions'), findsOneWidget);
      expect(find.text('Fostering'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(
        find.byKey(const Key('guardian_bottom_navigation')),
        findsOneWidget,
      );
    });

    testWidgets('appears in shell below 600px width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildCompactShell(
          prefs: prefs,
          currentLocation: '/pc/home',
          viewport: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('guardian_bottom_navigation')),
        findsOneWidget,
      );
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('is hidden in shell at 600px width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildCompactShell(
          prefs: prefs,
          currentLocation: '/pc/home',
          viewport: const Size(800, 900),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('guardian_bottom_navigation')), findsNothing);
    });

    testWidgets('appears on nested Guardian routes below 600px width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildCompactShell(
          prefs: prefs,
          currentLocation: '/pet/pet-1',
          viewport: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('guardian_bottom_navigation')),
        findsOneWidget,
      );
      expect(find.text('Pets'), findsOneWidget);
    });
  });
}
