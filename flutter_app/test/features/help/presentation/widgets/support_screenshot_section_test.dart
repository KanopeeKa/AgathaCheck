import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/support/screenshots/support_screenshot_section.dart';
import 'package:pet_profile_app/features/support/screenshots/support_screenshot_upload.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/test_helpers.dart';

Future<void> _pumpSection(
  WidgetTester tester, {
  required Locale locale,
  required List<SupportScreenshotUpload> screenshots,
  required void Function(List<SupportScreenshotUpload>) onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: SupportScreenshotSection(
          screenshots: screenshots,
          onChanged: onChanged,
          disabled: false,
        ),
      ),
    ),
  );
  await pumpApp(tester, frames: 3);
}

Uint8List _onePixelPng() => base64.decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  testWidgets('EN screenshot section exposes keyboard add control', (tester) async {
    await _pumpSection(
      tester,
      locale: const Locale('en'),
      screenshots: const [],
      onChanged: (_) {},
    );

    expect(find.byKey(const Key('support_screenshot_add')), findsOneWidget);
    expect(find.text('Add screenshot'), findsOneWidget);
    expect(
      find.text(
        'Screenshots may show personal information. Remove anything you do not want our team to store.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('FR screenshot section shows localized controls', (tester) async {
    await _pumpSection(
      tester,
      locale: const Locale('fr'),
      screenshots: const [],
      onChanged: (_) {},
    );

    expect(find.text('Ajouter une capture'), findsOneWidget);
    expect(
      find.textContaining('données personnelles'),
      findsOneWidget,
    );
  });

  testWidgets('remove button drops a pending screenshot', (tester) async {
    var current = [
      SupportScreenshotUpload(filename: 'shot.png', bytes: _onePixelPng()),
    ];
    await _pumpSection(
      tester,
      locale: const Locale('en'),
      screenshots: current,
      onChanged: (next) => current = next,
    );

    expect(find.byKey(const Key('support_screenshot_item_0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('support_screenshot_remove_0')));
    await pumpApp(tester);
    expect(current, isEmpty);
  });
}
