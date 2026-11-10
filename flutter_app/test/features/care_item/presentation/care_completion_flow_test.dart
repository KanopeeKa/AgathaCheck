import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/care_item/data/care_item_remote_datasource.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../domain/care_item_test_data.dart';

void main() {
  testWidgets('done snackbar Change date uses inverse text and an underline', (
    tester,
  ) async {
    final client = MockClient((request) async {
      return http.Response(jsonEncode({'undo_token': 'undo-1'}), 200);
    });
    final flow = CareCompletionFlow(
      CareCompletionService(
        CareItemRemoteDataSource(client: client, baseUrl: 'http://localhost'),
      ),
    );
    // Fixed overdue with a later dose today: DN-5 offers Change date.
    final item = schedule([
      occ('m', 10, CareOccurrenceStatus.overdue, time: '08:00'),
      occ('e', 10, CareOccurrenceStatus.due, time: '18:00'),
    ], at: asOf(10, '10:00'));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  flow.done(
                    context,
                    schedule: item,
                    onChanged: () async {},
                    source: CareCommandSource.agenda,
                  );
                },
                child: const Text('Mark done'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mark done'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Heartworm pill done'), findsOneWidget);
    expect(find.text('Change date'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    final link = find.byKey(const Key('care_done_change_date'));
    final button = tester.widget<TextButton>(link);
    expect(
      button.style?.foregroundColor?.resolve(const <WidgetState>{}),
      AppColorTokens.inverse,
    );
    final changeDate = find.text('Change date');
    final text = tester.widget<Text>(changeDate);
    final effective = DefaultTextStyle.of(
      tester.element(changeDate),
    ).style.merge(text.style);
    expect(effective.color, AppColorTokens.inverse);
    expect(effective.decoration, TextDecoration.underline);
    expect(effective.decorationColor, AppColorTokens.inverse);
    expect(effective.color, isNot(AppColorTokens.petCarePrimary));

    final box = tester.getSize(link);
    expect(box.width, greaterThanOrEqualTo(48));
    expect(box.height, greaterThanOrEqualTo(48));

    final undo = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
    expect(undo.label, 'Undo');
  });
}
