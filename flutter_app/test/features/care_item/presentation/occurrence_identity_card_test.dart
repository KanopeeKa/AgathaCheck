import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/occurrence/occurrence_identity_card.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

OccurrenceDetail _detail({
  CareOccurrenceStatus status = CareOccurrenceStatus.done,
}) {
  return OccurrenceDetail(
    item: CareItemSummary(
      id: 'e1',
      petId: 'p1',
      name: 'Groom',
      careFamily: 'grooming',
      isFixedSchedule: true,
      status: 'active',
      asOf: CareAsOf(
        date: DateTime(2026, 10, 6),
        time: '09:00',
        timezone: 'UTC',
      ),
    ),
    occurrence: CareOccurrence(
      id: 'o1',
      date: DateTime(2026, 10, 6),
      status: status,
      origin: CareOccurrenceOrigin.schedule,
      isOpen: status != CareOccurrenceStatus.done,
      completedOn: status == CareOccurrenceStatus.done
          ? DateTime(2026, 10, 6)
          : null,
    ),
  );
}

void main() {
  testWidgets('shows Done pill for a completed occurrence', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));

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
            body: OccurrenceIdentityCard(
              detail: _detail(),
              onOpenCareDetails: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l.done), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('occurrence_identity_card'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('occurrence_open_care_details'),
      findsOneWidget,
    );
  });
}
