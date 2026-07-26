import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/widgets/dashboard_section.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_shell_home_content.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/controllers/pet_list_controller.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_my_pets_section.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/vet/domain/entities/vet.dart';
import 'package:pet_profile_app/features/vet/presentation/providers/vet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

void main() {
  final pets = List.generate(
    6,
    (i) => Pet(id: 'pet-$i', name: 'Pet $i', species: 'Dog', breed: 'Mix'),
  );

  final vets = [
    const Vet(id: 'vet-1', name: 'Dr. Smith', address: 'Springfield'),
  ];

  Widget buildDashboard({List<Pet>? petList}) {
    final list = petList ?? pets;
    return ProviderScope(
      overrides: [
        petListProvider.overrideWith(() => TestPetListNotifier(list)),
        vetListProvider.overrideWith(() => _TestVetListNotifier(vets)),
        healthEntriesNotifierProvider.overrideWith(
          FakeHealthEntriesNotifier.new,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GuardianShellHomeContent(
            allPets: list,
            controller: PetListController(),
          ),
        ),
      ),
    );
  }

  testWidgets('dashboard shows exactly three sections', (tester) async {
    await tester.pumpWidget(buildDashboard());
    await tester.pumpAndSettle();

    expect(find.text('My Pets'), findsOneWidget);
    expect(find.text('Upcoming Pet Events'), findsOneWidget);
    expect(find.text('My vets'), findsOneWidget);
    expect(find.text('All Events'), findsOneWidget);
    expect(find.text('All Vets'), findsOneWidget);
  });

  testWidgets('My Pets shows all personal pets with Manage pets link', (
    tester,
  ) async {
    await tester.pumpWidget(buildDashboard());
    await tester.pumpAndSettle();

    expect(find.text('Manage pets'), findsOneWidget);
    expect(find.text('Pet 0'), findsOneWidget);

    final listView = find.descendant(
      of: find.byType(GuardianMyPetsSection),
      matching: find.byType(ListView),
    );
    await tester.drag(listView, const Offset(-800, 0));
    await tester.pumpAndSettle();
    expect(find.text('Pet 5'), findsOneWidget);
  });

  testWidgets('empty state when no pets', (tester) async {
    await tester.pumpWidget(buildDashboard(petList: []));
    await tester.pumpAndSettle();

    expect(find.text('No pets yet'), findsOneWidget);
    expect(find.text('My Pets'), findsOneWidget);
  });
}

class _TestVetListNotifier extends VetListNotifier {
  _TestVetListNotifier(this._vets);

  final List<Vet> _vets;

  @override
  Future<List<Vet>> build() async => _vets;
}
