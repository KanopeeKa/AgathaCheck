import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/occurrence/occurrence_neighbors_module.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

OccurrenceDetail _detail({
  OccurrenceNeighborSummary? previous,
  OccurrenceNeighborSummary? next,
}) {
  return OccurrenceDetail(
    item: CareItemSummary(
      id: 'e1',
      petId: 'p1',
      name: 'Flea',
      isFixedSchedule: true,
      status: 'active',
      asOf: CareAsOf(
        date: DateTime(2026, 6, 10),
        time: '09:00',
        timezone: 'UTC',
      ),
    ),
    occurrence: CareOccurrence(
      id: 'occ-mid',
      date: DateTime(2026, 6, 10),
      status: CareOccurrenceStatus.due,
      origin: CareOccurrenceOrigin.schedule,
      isOpen: true,
    ),
    previousOccurrence: previous,
    nextOccurrence: next,
  );
}

void main() {
  testWidgets('stacks neighbour slots at 320dp and text scale 2.0', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: OccurrenceNeighborsModule(
                petId: 'p1',
                entryId: 'e1',
                detail: _detail(
                  previous: OccurrenceNeighborSummary(
                    id: 'occ-prev',
                    scheduledDate: DateTime(2026, 6, 5),
                    occurrenceStatus: 'done',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsIdentifier('occurrence_neighbors_section'),
      findsOneWidget,
    );
    expect(find.text('No later date'), findsOneWidget);
  });
}
