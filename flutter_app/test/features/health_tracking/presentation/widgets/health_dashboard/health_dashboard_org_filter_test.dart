import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_dashboard/health_dashboard_org_filter.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

Widget _wrap(Widget child, List<Pet> pets) {
  return ProviderScope(
    overrides: [allPetsIncludingOrgProvider.overrideWith((ref) async => pets)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('renders nothing when there are no organization pets', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        HealthDashboardOrgFilter(selectedFilter: null, onFilterChanged: (_) {}),
        const [Pet(id: 'p1', name: 'Rex', species: 'Dog')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FilterChip), findsNothing);
  });

  testWidgets('renders chips and reports selection changes', (tester) async {
    String? selected;
    await tester.pumpWidget(
      _wrap(
        HealthDashboardOrgFilter(
          selectedFilter: null,
          onFilterChanged: (value) => selected = value,
        ),
        const [
          Pet(id: 'p1', name: 'Rex', species: 'Dog'),
          Pet(
            id: 'p2',
            name: 'Milo',
            species: 'Cat',
            organizationId: 'org-1',
            organizationName: 'Shelter A',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FilterChip), findsNWidgets(3));
    expect(find.text('Shelter A'), findsOneWidget);
    expect(find.byIcon(Icons.business), findsOneWidget);

    await tester.tap(find.text('Shelter A'));
    expect(selected, 'Shelter A');
  });
}
