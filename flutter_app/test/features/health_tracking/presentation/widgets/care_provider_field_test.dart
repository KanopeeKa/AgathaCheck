import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/care_provider_field.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('CareProviderField exposes care provider picker', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Material(
          child: CareProviderField(
            onChanged: ({contactId, typedName}) {},
            contacts: const [
              CareProviderContactOption(id: 'c1', name: 'Dr Vet'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String?>), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);
  });
}
