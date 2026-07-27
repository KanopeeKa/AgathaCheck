import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/due_event_card.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  group('DueEventCard', () {
    final dateFormat = DateFormat('dd MMM yy');
    const pet = Pet(
      id: 'pet-1',
      name: 'Bella',
      species: 'Dog',
      colorValue: 0xFF2196F3,
    );

    final overdueEntry = HealthEntry(
      id: 'entry-1',
      petId: 'pet-1',
      name: 'Heartworm',
      type: HealthEntryType.preventive,
      frequency: HealthFrequency.monthly,
      startDate: DateTime(2024, 1, 1),
      nextDueDate: DateTime(2020, 1, 1),
    );

    Widget buildCard(
      HealthEntry entry, {
      Pet? cardPet,
      bool showActions = true,
    }) {
      return ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: DueEventCard(
              entry: entry,
              pet: cardPet,
              showActions: showActions,
            ),
          ),
        ),
      );
    }

    testWidgets('shows pet name, event name, and status date', (tester) async {
      await tester.pumpWidget(buildCard(overdueEntry, cardPet: pet));
      await tester.pumpAndSettle();

      expect(find.text('Bella'), findsOneWidget);
      expect(find.text('Heartworm'), findsOneWidget);
      expect(
        find.text(dateFormat.format(overdueEntry.nextDueDate!)),
        findsOneWidget,
      );
    });

    testWidgets('shows action columns when showActions is true', (tester) async {
      await tester.pumpWidget(buildCard(overdueEntry, cardPet: pet));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('due_event_open_entry-1')), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Snooze'), findsOneWidget);
      expect(find.text('Mark as done'), findsOneWidget);
    });

    testWidgets('hides action columns when showActions is false', (tester) async {
      await tester.pumpWidget(
        buildCard(overdueEntry, cardPet: pet, showActions: false),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('due_event_open_entry-1')), findsNothing);
      expect(find.text('Open'), findsNothing);
      expect(find.text('Snooze'), findsNothing);
    });
  });
}
