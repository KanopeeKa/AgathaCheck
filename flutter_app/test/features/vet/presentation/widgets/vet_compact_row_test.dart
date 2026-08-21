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

  Widget buildRow({
    Vet rowVet = vet,
    int? linkedPetCount = 2,
    Locale? locale,
    TextScaler textScaler = TextScaler.noScaling,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      locale: locale,
      theme: AppTheme.lightTheme.copyWith(
        splashFactory: NoSplash.splashFactory,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: VetCompactRow(
            vet: rowVet,
            linkedPetCount: linkedPetCount,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows name, location, and linked-pet count as scanable text', (
    tester,
  ) async {
    await tester.pumpWidget(buildRow());
    await tester.pumpAndSettle();

    expect(find.text('Dr. Smith'), findsOneWidget);
    expect(find.text('Springfield'), findsOneWidget);
    expect(find.text('2 pets'), findsOneWidget);
  });

  testWidgets('uses localized singular and plural linked-pet counts', (
    tester,
  ) async {
    await tester.pumpWidget(buildRow(linkedPetCount: 3));
    await tester.pumpAndSettle();

    expect(find.text('3 pets'), findsOneWidget);

    await tester.pumpWidget(
      buildRow(linkedPetCount: 1, locale: const Locale('fr')),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 animal'), findsOneWidget);
  });

  testWidgets('keeps long names, addresses, and counts visible at 200% scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const longVet = Vet(
      id: 'long-vet',
      name: 'Clinique vétérinaire des animaux de compagnie du quartier nord',
      address: '42 avenue des Tilleuls, 75019 Paris',
    );

    await tester.pumpWidget(
      buildRow(
        rowVet: longVet,
        linkedPetCount: 12,
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(longVet.name), findsOneWidget);
    expect(find.text('75019 Paris'), findsOneWidget);
    expect(find.text('12 pets'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('omits only an unresolved count, not available vet context', (
    tester,
  ) async {
    await tester.pumpWidget(buildRow(linkedPetCount: null));
    await tester.pumpAndSettle();

    expect(find.text('Dr. Smith'), findsOneWidget);
    expect(find.text('Springfield'), findsOneWidget);
    expect(find.textContaining('pet'), findsNothing);
  });

  testWidgets('has one complete semantic button label and supports tap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(buildRow(linkedPetCount: 3, onTap: () => taps++));
    await tester.pumpAndSettle();

    final semantics = tester.ensureSemantics();
    final row = find.bySemanticsLabel('Dr. Smith, Springfield, 3 pets');
    expect(row, findsOneWidget);
    semantics.dispose();

    await tester.tap(row);
    expect(taps, 1);
  });
}
