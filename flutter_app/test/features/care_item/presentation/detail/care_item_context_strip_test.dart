import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/detail/care_item_context_strip.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  const pet = Pet(
    id: 'pet-1',
    name: 'Buddy',
    species: 'Dog',
    colorValue: 0xFF2196F3,
  );

  HealthEntry baseEntry({String status = 'active'}) => HealthEntry(
    id: 'e1',
    petId: 'pet-1',
    name: 'Heart tablet',
    type: HealthEntryType.medication,
    status: status,
    frequency: HealthFrequency.monthly,
    frequencyInterval: 1,
    startDate: DateTime(2025, 1, 1),
  );

  Future<void> pumpStrip(
    WidgetTester tester, {
    required HealthEntry entry,
    required double viewportWidth,
    required double stripWidth,
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(Size(viewportWidth, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiBaseUrlProvider.overrideWithValue('/backend')],
        child: MediaQuery(
          data: MediaQueryData(
            size: Size(viewportWidth, 800),
            textScaler: TextScaler.linear(textScale),
          ),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: stripWidth,
                child: CareItemContextStrip(entry: entry, pet: pet),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('careItemStripChip', () {
    test('Finished when status is completed', () {
      expect(careItemStripChip(baseEntry(status: 'completed')), isNotNull);
    });

    test('Paused when status is paused', () {
      expect(careItemStripChip(baseEntry(status: 'paused')), isNotNull);
    });

    test('Finished wins over paused when completed', () {
      final entry = baseEntry(status: 'completed');
      expect(entry.isPaused, isFalse);
      expect(careItemStripChip(entry), isNotNull);
    });

    test('null when active', () {
      expect(careItemStripChip(baseEntry(status: 'active')), isNull);
    });
  });

  testWidgets('shows Finished chip when status is completed', (tester) async {
    await pumpStrip(
      tester,
      entry: baseEntry(status: 'completed'),
      viewportWidth: 400,
      stripWidth: 400,
    );

    expect(find.text('Finished'), findsOneWidget);
    expect(find.text('Heart tablet'), findsOneWidget);
  });

  testWidgets('shows Paused chip when status is paused', (tester) async {
    await pumpStrip(
      tester,
      entry: baseEntry(status: 'paused'),
      viewportWidth: 400,
      stripWidth: 400,
    );

    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Finished'), findsNothing);
  });

  testWidgets('shows no status chip when active', (tester) async {
    await pumpStrip(
      tester,
      entry: baseEntry(status: 'active'),
      viewportWidth: 400,
      stripWidth: 400,
    );

    expect(find.text('Finished'), findsNothing);
    expect(find.text('Paused'), findsNothing);
    expect(find.byKey(const Key('care_item_context_strip_chip')), findsNothing);
  });

  testWidgets('uses stacked layout at narrow strip width', (tester) async {
    await pumpStrip(
      tester,
      entry: baseEntry(),
      viewportWidth: 400,
      stripWidth: 320,
    );

    final stripColumn = tester.widget<Column>(
      find.byKey(const Key('care_item_context_strip')),
    );
    expect(stripColumn.mainAxisSize, MainAxisSize.min);
    expect(find.text('Buddy'), findsOneWidget);
  });

  testWidgets('uses stacked layout at large text scale', (tester) async {
    await pumpStrip(
      tester,
      entry: baseEntry(),
      viewportWidth: 500,
      stripWidth: 400,
      textScale: 1.3,
    );

    expect(find.byKey(const Key('care_item_context_strip')), findsOneWidget);
    expect(find.text('Buddy'), findsOneWidget);
  });

  testWidgets('care name uses titleMedium w700 at wide viewport', (
    tester,
  ) async {
    await pumpStrip(
      tester,
      entry: baseEntry(),
      viewportWidth: 800,
      stripWidth: 700,
    );

    final title = tester.widget<Text>(
      find.byKey(const Key('care_item_context_strip_title')),
    );
    expect(title.style?.fontWeight, FontWeight.w700);
    expect(title.style?.fontSize, 16);
  });

  testWidgets('care name uses titleLarge below compact breakpoint', (
    tester,
  ) async {
    await pumpStrip(
      tester,
      entry: baseEntry(),
      viewportWidth: 500,
      stripWidth: 480,
    );

    final title = tester.widget<Text>(
      find.byKey(const Key('care_item_context_strip_title')),
    );
    expect(title.style?.fontSize, 22);
  });

  testWidgets('pet tile exposes button semantics', (tester) async {
    await pumpStrip(
      tester,
      entry: baseEntry(),
      viewportWidth: 400,
      stripWidth: 400,
    );
    final handle = tester.ensureSemantics();

    final semantics = tester.getSemantics(
      find.bySemanticsIdentifier('care_item_pet_tile'),
    );
    expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(semantics.label, contains('Buddy'));
    handle.dispose();
  });

  testWidgets('care name is a semantics header', (tester) async {
    await pumpStrip(
      tester,
      entry: baseEntry(),
      viewportWidth: 400,
      stripWidth: 400,
    );
    final handle = tester.ensureSemantics();

    final semantics = tester.getSemantics(
      find.byKey(const Key('care_item_context_strip_title')),
    );
    expect(semantics.hasFlag(SemanticsFlag.isHeader), isTrue);
    handle.dispose();
  });

  testWidgets('pet tile opens pet detail with returnTo', (tester) async {
    final router = GoRouter(
      initialLocation: '/pet/pet-1/events/e1',
      routes: [
        GoRoute(
          path: '/pet/:petId',
          builder: (context, state) => Scaffold(
            body: Text(
              'Pet ${state.pathParameters['petId']}|'
              '${state.uri.queryParameters['returnTo'] ?? ''}',
            ),
          ),
          routes: [
            GoRoute(
              path: 'events/:entryId',
              builder: (context, state) => Scaffold(
                body: CareItemContextStrip(entry: baseEntry(), pet: pet),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiBaseUrlProvider.overrideWithValue('/backend')],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsIdentifier('care_item_pet_tile'));
    await tester.pumpAndSettle();

    expect(find.text('Pet pet-1|/pet/pet-1/events/e1'), findsOneWidget);
  });
}
