import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/widgets/dashboard_section.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/pet_events_preview_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/fakes.dart';

class _FakeHealthEntriesNotifier extends HealthEntriesNotifier {
  _FakeHealthEntriesNotifier(this._entries);

  final List<HealthEntry> _entries;

  @override
  Future<List<HealthEntry>> build() async => _entries;
}

void main() {
  const pet = Pet(id: 'pet-1', name: 'Bella', species: 'Dog');

  testWidgets('pet events preview shows due and overdue title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthEntriesNotifierProvider.overrideWith(
            FakeHealthEntriesNotifier.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: PetEventsPreviewSection(petId: 'pet-1', pet: pet),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Due and Overdue'), findsOneWidget);
    expect(find.byType(DashboardSection), findsOneWidget);
    expect(find.text('Manage events'), findsOneWidget);
  });

  testWidgets('pet events preview lists due entries for pet', (tester) async {
    final dueEntry = HealthEntry(
      id: 'entry-1',
      petId: 'pet-1',
      name: 'Rabies vaccine',
      type: HealthEntryType.preventive,
      frequency: HealthFrequency.once,
      startDate: DateTime(2024, 1, 1),
      nextDueDate: DateTime(2020, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthEntriesNotifierProvider.overrideWith(
            () => _FakeHealthEntriesNotifier([dueEntry]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: PetEventsPreviewSection(petId: 'pet-1', pet: pet),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rabies vaccine'), findsOneWidget);
    expect(find.text('Bella'), findsOneWidget);
  });
}
