import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/presentation/sheets/postpone_sheet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('postpone sheet exposes semantics identifier', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PostponeSheet(
              entryId: 'entry-1',
              isFixedSchedule: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsIdentifier('postpone_sheet'), findsOneWidget);
    expect(find.byKey(const Key('postpone_no_end_date')), findsOneWidget);
    expect(find.byKey(const Key('postpone_confirm')), findsOneWidget);
  });
}
