import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/domain/entities/people_contact.dart';
import 'package:pet_profile_app/features/people/domain/entities/person_roster_entry.dart';
import 'package:pet_profile_app/features/people/presentation/widgets/people_directory_card.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  testWidgets('PeopleDirectoryCard exposes semantics and tap', (tester) async {
    var tapped = false;
    const contact = PeopleContact(
      id: 'c1',
      kind: 'person',
      name: 'Jamie Lee',
      roles: ['sitter'],
    );
    final entry = PersonRosterEntry.fromContact(contact, linkedPetCount: 2);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PeopleDirectoryCard(
            entry: entry,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('people_directory_card_c1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('people_directory_card_c1')));
    expect(tapped, isTrue);
  });
}
