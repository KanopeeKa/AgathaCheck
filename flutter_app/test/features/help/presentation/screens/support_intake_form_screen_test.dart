import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/features/support/form/application/support_form_providers.dart';
import 'package:pet_profile_app/features/support/form/data/support_tickets_api.dart';
import 'package:pet_profile_app/features/support/form/presentation/screens/support_intake_form_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/test_helpers.dart';

Future<void> _pumpForm(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...overrides,
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: SupportIntakeFormScreen(),
      ),
    ),
  );
  await pumpApp(tester, frames: 5);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('failed validation shows error summary with focus target', (
    tester,
  ) async {
    await _pumpForm(tester);

    await tester.tap(find.byKey(const Key('support_form_submit')));
    await pumpApp(tester);

    expect(find.byKey(const Key('support_form_error_summary')), findsOneWidget);
    expect(find.text('There is a problem with this form'), findsOneWidget);
    expect(WidgetsBinding.instance.focusManager.primaryFocus, isNotNull);
  });

  testWidgets('successful submit shows reference', (tester) async {
    final client = MockClient((request) async {
      expect(request.url.path, endsWith('/api/support/tickets'));
      return http.Response(
        json.encode({'reference': 'AT-ABCDEFGH'}),
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    await _pumpForm(
      tester,
      overrides: [
        supportTicketsApiProvider.overrideWith(
          (ref) => SupportTicketsApi(baseUrl: 'http://test', client: client),
        ),
      ],
    );

    await tester.enterText(
      find.byKey(const Key('support_form_title')),
      'Login bug',
    );
    await tester.enterText(
      find.byKey(const Key('support_form_description')),
      'Cannot sign in on Safari.',
    );
    await tester.enterText(
      find.byKey(const Key('support_form_email')),
      'user@example.com',
    );

    await tester.tap(find.byKey(const Key('support_form_submit')));
    await pumpApp(tester, frames: 8);

    expect(find.byKey(const Key('support_form_success')), findsOneWidget);
    expect(find.text('AT-ABCDEFGH'), findsOneWidget);
  });
}
