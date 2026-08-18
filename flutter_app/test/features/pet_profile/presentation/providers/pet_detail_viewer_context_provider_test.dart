import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_viewer_role.dart';
import 'package:pet_profile_app/features/pet_profile/domain/services/pet_detail_actions.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_detail_viewer_context_provider.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LoadedOrgsNotifier extends OrganizationListNotifier {
  _LoadedOrgsNotifier(this.orgs);

  final List<Organization> orgs;

  @override
  Future<List<Organization>> build() async => orgs;
}

Future<void> _waitForPolicyInputs(ProviderContainer container) async {
  await container.read(allPetsIncludingOrgProvider.future);
  await container.read(organizationListProvider.future);
}

Future<ProviderContainer> _container(List<Override> overrides) async {
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      ...overrides,
    ],
  );
  return container;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const pet = Pet(id: 'p1', name: 'Max', species: 'Dog');

  test('returns restricted context while pets are loading', () async {
    final container = await _container([
      allPetsIncludingOrgProvider.overrideWith(
        (ref) => Completer<List<Pet>>().future,
      ),
      organizationListProvider.overrideWith(
        () => _LoadedOrgsNotifier(const []),
      ),
    ]);
    addTearDown(container.dispose);

    final ctx = container.read(petDetailViewerContextProvider('p1'));
    expect(ctx.isPolicyResolved, isFalse);
    expect(ctx.can(PetDetailAction.editProfile), isFalse);
  });

  test('resolves guardian actions when inputs are ready', () async {
    final container = await _container([
      allPetsIncludingOrgProvider.overrideWith((ref) async => const [pet]),
      organizationListProvider.overrideWith(
        () => _LoadedOrgsNotifier(const []),
      ),
    ]);
    addTearDown(container.dispose);
    await _waitForPolicyInputs(container);

    final ctx = container.read(petDetailViewerContextProvider('p1'));
    expect(ctx.isPolicyResolved, isTrue);
    expect(ctx.can(PetDetailAction.editProfile), isTrue);
    expect(ctx.can(PetDetailAction.downloadReport), isTrue);
  });

  test('recomputes when experience switches at runtime', () async {
    final orgPet = Pet(
      id: 'org-p1',
      name: 'Shelter Cat',
      species: 'Cat',
      organizationId: 'o1',
      organizationName: 'Shelter',
    );
    final container = await _container([
      allPetsIncludingOrgProvider.overrideWith((ref) async => [orgPet]),
      organizationListProvider.overrideWith(
        () => _LoadedOrgsNotifier(const [
          Organization(
            id: 'o1',
            name: 'Shelter',
            type: OrganizationType.charity,
            role: 'admin',
          ),
        ]),
      ),
    ]);
    addTearDown(container.dispose);
    await _waitForPolicyInputs(container);

    // Now uses resolveAutoExperience which will return organization since there's no guardian pet context
    final orgCtx = container.read(
      petDetailViewerContextProvider('org-p1'),
    );
    expect(orgCtx.role, PetViewerRole.organization);
    expect(orgCtx.can(PetDetailAction.fosterPlacement), isTrue);
  });
}
