import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/pet_form_screen.dart';
import 'package:pet_profile_app/features/vet/domain/entities/vet.dart';
import 'package:pet_profile_app/features/vet/presentation/providers/vet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../providers/pet_list_notifier_test.dart';

class _ExistingPetNotifier extends PetListNotifier {
  _ExistingPetNotifier(this.pet);

  final Pet pet;

  @override
  Future<List<Pet>> build() async => [pet];
}

class _VetsNotifier extends VetListNotifier {
  @override
  Future<List<Vet>> build() async => const [
    Vet(
      id: 'vet-1',
      name: 'Dr Smith',
      phone: '01234',
      email: 'vet@example.com',
      address: '1 Vet Road',
    ),
  ];
}

class _OrgsNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => const [
    Organization(
      id: 'org-1',
      name: 'Happy Paws Clinic',
      type: OrganizationType.professional,
      role: 'super_user',
    ),
  ];
}

Widget _wrapAddForm({RecordingPetRepository? repo, String? initialOrgId}) {
  final repository = repo ?? RecordingPetRepository();
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => PetFormScreen(initialOrgId: initialOrgId),
      ),
      GoRoute(
        path: '/organizations/:orgId',
        builder: (context, state) =>
            Scaffold(body: Text('Org ${state.pathParameters['orgId']}')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      petRepositoryProvider.overrideWithValue(repository),
      organizationListProvider.overrideWith(_OrgsNotifier.new),
      vetListProvider.overrideWith(_VetsNotifier.new),
      apiBaseUrlProvider.overrideWithValue('http://test.local'),
      allPetsIncludingOrgProvider.overrideWith((ref) async => <Pet>[]),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

Widget _wrap(Pet pet) {
  return ProviderScope(
    overrides: [
      petListProvider.overrideWith(() => _ExistingPetNotifier(pet)),
      vetListProvider.overrideWith(_VetsNotifier.new),
      apiBaseUrlProvider.overrideWithValue('http://test.local'),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PetFormScreen(petId: 'pet-1'),
    ),
  );
}

String _fieldText(WidgetTester tester, Key fieldKey) {
  final editable = tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(fieldKey),
      matching: find.byType(EditableText),
    ),
  );
  return editable.controller.text;
}

FilledButton _saveButton(WidgetTester tester) {
  return tester.widget<FilledButton>(find.byKey(const Key('save_pet_button')));
}

void main() {
  testWidgets('prefills existing pet information when editing', (tester) async {
    final pet = Pet(
      id: 'pet-1',
      name: 'Bella',
      species: 'Dog',
      breed: 'Collie',
      dateOfBirth: DateTime(2020, 3, 15),
      weight: 12.5,
      gender: 'Female',
      bio: 'Loves long walks',
      insurance: 'PetPlan policy 123',
      neuteredDate: DateTime(2021, 6, 20),
      chipId: 'CHIP-123',
      vetId: 'vet-1',
    );

    await tester.pumpWidget(_wrap(pet));
    await tester.pump();
    await tester.pump();

    expect(find.text('Edit Bella'), findsOneWidget);
    expect(find.text('Basic details'), findsOneWidget);
    expect(find.text('Health details'), findsOneWidget);
    expect(find.text('About Bella'), findsOneWidget);
    expect(find.text('Care & records'), findsOneWidget);
    expect(find.text('Change photo'), findsOneWidget);
    expect(_fieldText(tester, const Key('pet_name_field')), 'Bella');
    expect(_fieldText(tester, const Key('pet_breed_field')), 'Collie');
    expect(_fieldText(tester, const Key('pet_weight_field')), '12.5');
    expect(_fieldText(tester, const Key('pet_bio_field')), 'Loves long walks');
    expect(
      _fieldText(tester, const Key('pet_insurance_field')),
      'PetPlan policy 123',
    );
    expect(_fieldText(tester, const Key('pet_chip_id_field')), 'CHIP-123');

    expect(find.text('Dog'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(
      find.text(formatCalendarDateMedium(DateTime(2020, 3, 15))),
      findsOneWidget,
    );
    expect(
      find.text(formatCalendarDateMedium(DateTime(2021, 6, 20))),
      findsOneWidget,
    );
    expect(find.text('Dr Smith'), findsOneWidget);
  });

  testWidgets('save is disabled until the form is dirty', (tester) async {
    final pet = Pet(id: 'pet-1', name: 'Bella', species: 'Dog');

    await tester.pumpWidget(_wrap(pet));
    await tester.pump();
    await tester.pump();

    expect(_saveButton(tester).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('pet_name_field')), 'Bella!');
    await tester.pump();

    expect(_saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('creates an organisation pet when initialOrgId is provided', (
    tester,
  ) async {
    final repo = RecordingPetRepository();

    await tester.pumpWidget(_wrapAddForm(repo: repo, initialOrgId: 'org-1'));
    await tester.pumpAndSettle();

    expect(find.text('Happy Paws Clinic'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pet_name_field')), 'Bella');
    await tester.tap(find.byKey(const Key('pet_species_chip_Dog')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('save_pet_button')));
    await tester.tap(find.byKey(const Key('save_pet_button')));
    await tester.pumpAndSettle();

    expect(repo.added, hasLength(1));
    expect(repo.added.single.name, 'Bella');
    expect(repo.added.single.organizationId, 'org-1');
  });
}
