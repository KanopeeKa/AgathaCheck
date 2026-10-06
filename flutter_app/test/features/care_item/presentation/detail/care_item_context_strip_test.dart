import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/detail/care_item_context_strip.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  const pet = Pet(
    id: 'pet-1',
    name: 'Buddy',
    species: 'Dog',
    colorValue: 0xFF2196F3,
  );

  testWidgets('shows Finished chip when status is completed', (tester) async {
    final entry = HealthEntry(
      id: 'e1',
      petId: 'pet-1',
      name: 'Heart tablet',
      type: HealthEntryType.medication,
      status: 'completed',
      frequency: HealthFrequency.monthly,
      frequencyInterval: 1,
      startDate: DateTime(2025, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiBaseUrlProvider.overrideWithValue('/backend')],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: CareItemContextStrip(entry: entry, pet: pet),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Finished'), findsOneWidget);
    expect(find.text('Care details'), findsNothing);
    expect(find.text('Heart tablet'), findsOneWidget);
  });
}
