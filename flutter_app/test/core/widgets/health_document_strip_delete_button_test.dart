import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/widgets/health_document_strip_delete_button.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('delete overlay meets 48dp minimum size', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Stack(
            children: [
              HealthDocumentStripDeleteButton(
                semanticsLabel: 'Remove document',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    final button = tester.getSize(find.byType(IconButton));
    expect(button.width, greaterThanOrEqualTo(48));
    expect(button.height, greaterThanOrEqualTo(48));
  });
}
