import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/detail/care_item_history_section.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/pet_event_view_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

HealthEntry _entry() => HealthEntry(
  id: 'entry-1',
  petId: 'pet-1',
  name: 'Meds',
  type: HealthEntryType.medication,
  frequency: HealthFrequency.daily,
  status: 'active',
  startDate: DateTime(2026, 1, 1),
);

List<HealthOccurrence> _past(int count) => List.generate(
  count,
  (i) => HealthOccurrence(
    id: 'past-$i',
    entryId: 'entry-1',
    scheduledDate: DateTime(2026, 6, i + 1),
    status: 'completed',
    completedOn: DateTime(2026, 6, i + 1),
  ),
);

void main() {
  testWidgets('hides See history when at most inline cap rows', (tester) async {
    var seeTapped = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entryPastOccurrencesProvider(
            'entry-1',
          ).overrideWith((ref) async => _past(3)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemHistorySection(
              entry: _entry(),
              muted: false,
              pastOccurrencesVisibleCap: 3,
              onSeeHistory: () => seeTapped = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('care_item_see_history')), findsNothing);
  });

  testWidgets('shows See history when more rows than cap', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entryPastOccurrencesProvider(
            'entry-1',
          ).overrideWith((ref) async => _past(4)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemHistorySection(
              entry: _entry(),
              muted: false,
              pastOccurrencesVisibleCap: 3,
              onSeeHistory: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('care_item_see_history')), findsOneWidget);
  });
}
