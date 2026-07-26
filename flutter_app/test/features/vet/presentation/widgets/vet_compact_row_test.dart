import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/vet/domain/entities/vet.dart';
import 'package:pet_profile_app/features/vet/presentation/widgets/vet_compact_row.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  const vet = Vet(
    id: 'vet-1',
    name: 'Dr. Smith',
    address: '123 Main St, Springfield',
  );

  Widget buildRow({int linkedPetCount = 2}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: VetCompactRow(
          vet: vet,
          linkedPetCount: linkedPetCount,
          onTap: () {},
        ),
      ),
    );
  }

  testWidgets('shows name and city on one line', (tester) async {
    await tester.pumpWidget(buildRow());
    await tester.pumpAndSettle();

    expect(find.text('Dr. Smith · Springfield'), findsOneWidget);
  });

  testWidgets('shows linked pet count right-aligned', (tester) async {
    await tester.pumpWidget(buildRow(linkedPetCount: 3));
    await tester.pumpAndSettle();

    expect(find.text('3 pets'), findsOneWidget);
  });
}
