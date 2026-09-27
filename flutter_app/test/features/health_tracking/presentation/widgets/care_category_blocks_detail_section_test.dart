import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/care_item_blocks.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/care_category_blocks/care_category_blocks_detail_section.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  testWidgets('detail shows only populated vaccination visit fields', (
    tester,
  ) async {
    final entry = HealthEntry(
      id: 'e1',
      petId: 'pet-1',
      name: 'Rabies',
      type: HealthEntryType.preventive,
      frequency: HealthFrequency.yearly,
      startDate: DateTime(2026, 1, 1),
      careFamily: CareFamily.vaccination,
      careBlocks: const CareItemBlocks(
        visit: VisitBlock(questionsToAsk: 'Need titre test?'),
      ),
    );
    const pet = Pet(id: 'pet-1', name: 'Agatha', species: 'dog');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CareCategoryBlocksDetailSection(
            entry: entry,
            pet: pet,
            muted: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('care_category_blocks_detail')), findsOneWidget);
    expect(find.text('Need titre test?'), findsOneWidget);
  });
}
