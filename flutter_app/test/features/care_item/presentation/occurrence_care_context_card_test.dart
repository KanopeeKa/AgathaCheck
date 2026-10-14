import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/occurrence/occurrence_care_context_card.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

OccurrenceDetail _detail({
  String name = 'Groom',
  String? doseLine,
  String? strengthFormLine,
}) {
  return OccurrenceDetail(
    item: CareItemSummary(
      id: 'e1',
      petId: 'p1',
      name: name,
      careFamily: 'medication',
      isFixedSchedule: true,
      status: 'active',
      asOf: CareAsOf(
        date: DateTime(2026, 10, 6),
        time: '09:00',
        timezone: 'UTC',
      ),
      doseLine: doseLine,
      strengthFormLine: strengthFormLine,
    ),
    occurrence: CareOccurrence(
      id: 'o1',
      date: DateTime(2026, 10, 6),
      status: CareOccurrenceStatus.done,
      origin: CareOccurrenceOrigin.schedule,
      isOpen: false,
      completedOn: DateTime(2026, 10, 6),
    ),
  );
}

void main() {
  testWidgets('shows linked care name without View care details button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          petByIdProvider('p1').overrideWith(
            (ref) async =>
                Pet(id: 'p1', name: 'Buddy', species: 'dog', photoPath: null),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: OccurrenceCareContextCard(
              detail: _detail(doseLine: '1 tablet'),
              onOpenCareDetails: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Groom'), findsOneWidget);
    expect(find.text('1 tablet'), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('occurrence_care_context_card'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('occurrence_care_name_link'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('occurrence_open_care_details'),
      findsNothing,
    );
  });

  testWidgets('renders at 320dp width and text scale 2.0', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: ProviderScope(
          overrides: [
            petByIdProvider('p1').overrideWith(
              (ref) async => Pet(
                id: 'p1',
                name: 'Buddy',
                species: 'dog',
                photoPath: null,
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: OccurrenceCareContextCard(
                detail: _detail(
                  strengthFormLine: '10 mg · tablet',
                ),
                onOpenCareDetails: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('10 mg · tablet'), findsOneWidget);
  });
}
