import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

class _VetsNotifier extends VetListNotifier {
  @override
  Future<List<Vet>> build() async => const [];
}

class _OrgsNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => const [];
}

Widget _wrapAddForm({double width = 320}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const PetFormScreen()),
    ],
  );
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      petRepositoryProvider.overrideWithValue(RecordingPetRepository()),
      organizationListProvider.overrideWith(_OrgsNotifier.new),
      vetListProvider.overrideWith(_VetsNotifier.new),
      apiBaseUrlProvider.overrideWithValue('http://test.local'),
      allPetsIncludingOrgProvider.overrideWith((ref) async => <Pet>[]),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: child!,
      ),
    ),
  );
}

class _ExistingPetNotifier extends PetListNotifier {
  _ExistingPetNotifier(this.pet);

  final Pet pet;

  @override
  Future<List<Pet>> build() async => [pet];
}

Widget _wrapEditForm({required double width}) {
  final pet = Pet(
    id: 'pet-1',
    name: 'Bella',
    species: 'Dog',
    breed: 'Collie',
    dateOfBirth: DateTime(2020, 3, 15),
    weight: 12.5,
    gender: 'Female',
  );

  return ProviderScope(
    overrides: [
      petListProvider.overrideWith(() => _ExistingPetNotifier(pet)),
      vetListProvider.overrideWith(_VetsNotifier.new),
      apiBaseUrlProvider.overrideWithValue('http://test.local'),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: const PetFormScreen(petId: 'pet-1'),
      ),
    ),
  );
}

void main() {
  group('PetFormScreen responsive layouts', () {
    testWidgets('phone (320px) uses sticky actions and stacked fields', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      await tester.pumpWidget(_wrapAddForm(width: 320));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pet_form_layout_phone')), findsOneWidget);
      expect(find.byKey(const Key('pet_form_sticky_actions')), findsOneWidget);
      expect(find.byKey(const Key('pet_form_preview_card')), findsNothing);
      expect(find.byKey(const Key('pet_form_species_breed_row')), findsNothing);
      expect(find.byKey(const Key('pet_form_dob_weight_row')), findsNothing);
      expect(find.byKey(const Key('save_pet_button')), findsOneWidget);
    });

    testWidgets('tablet (768px) uses centred layout with paired rows', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(768, 900));
      await tester.pumpWidget(_wrapAddForm(width: 768));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pet_form_layout_tablet')), findsOneWidget);
      expect(find.byKey(const Key('pet_form_sticky_actions')), findsNothing);
      expect(find.byKey(const Key('pet_form_preview_card')), findsNothing);
      expect(
        find.byKey(const Key('pet_form_species_breed_row')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('pet_form_dob_weight_row')), findsOneWidget);

      final tabletBox = tester.getRect(
        find.byKey(const Key('pet_form_layout_tablet')),
      );
      expect(tabletBox.width, lessThanOrEqualTo(768));
    });

    testWidgets('desktop (1280px) shows preview card and form pane', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(_wrapEditForm(width: 1280));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pet_form_layout_desktop')), findsOneWidget);
      expect(find.byKey(const Key('pet_form_preview_card')), findsOneWidget);
      expect(find.byKey(const Key('pet_form_sticky_actions')), findsNothing);
      expect(find.text('Bella'), findsWidgets);
      expect(find.text('Female'), findsWidgets);
    });

    testWidgets('save buttons meet 48dp minimum touch target', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      await tester.pumpWidget(_wrapAddForm(width: 320));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('pet_name_field')), 'Rex');
      await tester.pump();

      final saveButton = tester.getRect(
        find.byKey(const Key('save_pet_button')),
      );
      expect(saveButton.height, greaterThanOrEqualTo(48));
    });
  });
}
