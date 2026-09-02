import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_edit_permission_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EmptyOrgsNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => const [];
}

Future<List<Override>> _baseOverrides() async {
  final prefs = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    organizationListProvider.overrideWith(_EmptyOrgsNotifier.new),
  ];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('redirects shared carer away from edit deep link', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/edit/p1',
      routes: [
        GoRoute(
          path: '/pet/:id',
          builder: (context, state) =>
              Scaffold(body: Text('pet ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/edit/:id',
          builder: (context, state) => PetEditPermissionGuard(
            petId: state.pathParameters['id']!,
            child: const Scaffold(body: Text('edit form')),
          ),
        ),
      ],
    );

    final overrides = await _baseOverrides();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...overrides,
          allPetsIncludingOrgProvider.overrideWith(
            (ref) async => const [
              Pet(
                id: 'p1',
                name: 'Rex',
                species: 'Dog',
                isShared: true,
                primaryHolderName: 'Alex',
              ),
            ],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('edit form'), findsNothing);
    expect(find.text('pet p1'), findsOneWidget);
  });

  testWidgets('allows guardian owner to open edit form', (tester) async {
    final router = GoRouter(
      initialLocation: '/edit/p1',
      routes: [
        GoRoute(
          path: '/edit/:id',
          builder: (context, state) => PetEditPermissionGuard(
            petId: state.pathParameters['id']!,
            child: const Scaffold(body: Text('edit form')),
          ),
        ),
      ],
    );

    final overrides = await _baseOverrides();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...overrides,
          allPetsIncludingOrgProvider.overrideWith(
            (ref) async => const [Pet(id: 'p1', name: 'Rex', species: 'Dog')],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(find.text('edit form'), findsOneWidget);
  });
}
