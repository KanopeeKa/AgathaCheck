import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_profile_app/core/providers/http_client_provider.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/features/sharing/presentation/screens/shared_pet_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

Widget buildTestApp(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('SharedPetScreen renders loading indicator', (WidgetTester tester) async {
    final completer = Completer<http.Response>();
    final mockClient = http_testing.MockClient((request) => completer.future);

    await tester.pumpWidget(
      buildTestApp(
        const SharedPetScreen(shareCode: 'abc'),
        overrides: [
          httpClientProvider.overrideWithValue(mockClient),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(http.Response(
      json.encode({
        'pet': {'name': 'Buddy', 'species': 'Dog'},
        'health_entries': [],
        'vet': null,
        'owner': null,
      }),
      200,
    ));
    await tester.pumpAndSettle();
  });

  testWidgets('SharedPetScreen shows error on failed load', (WidgetTester tester) async {
    final mockClient = http_testing.MockClient((request) async {
      return http.Response('Not found', 404);
    });

    await tester.pumpWidget(
      buildTestApp(
        const SharedPetScreen(shareCode: 'invalid'),
        overrides: [
          httpClientProvider.overrideWithValue(mockClient),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Pet not found'), findsOneWidget);
  });
}
