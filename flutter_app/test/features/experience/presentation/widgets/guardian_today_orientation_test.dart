import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_dashboard_helpers.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_today_orientation.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  const pet = Pet(id: 'pet-1', name: 'Miso', species: 'Cat');
  final now = DateTime(2030, 5, 10);

  GuardianTodayCareSummary summary({
    int overdue = 2,
    int dueToday = 1,
    int upcoming = 3,
  }) {
    final entries = <HealthEntry>[
      ...List.generate(
        overdue,
        (index) => _entry(
          'overdue-$index',
          dueDate: now.subtract(Duration(days: index + 1)),
        ),
      ),
      ...List.generate(
        dueToday,
        (index) => _entry('today-$index', dueDate: now),
      ),
      ...List.generate(
        upcoming,
        (index) => _entry(
          'upcoming-$index',
          dueDate: now.add(Duration(days: index + 1)),
        ),
      ),
    ];
    return GuardianTodayCareSummary.forPets(
      entries: entries,
      pets: const [pet],
      now: now,
    );
  }

  Widget buildSubject({
    required GuardianTodayScreenState state,
    GuardianTodayCareSummary? careSummary,
    VoidCallback? onRetry,
    Locale locale = const Locale('en'),
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: GuardianTodayOrientation(
              state: state,
              summary: careSummary,
              onRetry: onRetry,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('attention presents every urgency count once in semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        state: GuardianTodayScreenState.attention,
        careSummary: summary(),
      ),
    );

    expect(find.text('2 overdue items'), findsOneWidget);
    expect(find.text('1 item due today'), findsOneWidget);
    expect(find.text('3 Care coming up'), findsOneWidget);
    final node = tester.getSemantics(
      find.byKey(const Key('guardian_today_orientation')),
    );
    expect(
      node.label,
      'Today: 2 overdue items. 1 item due today. 3 Care coming up.',
    );
    expect(
      find.bySemanticsLabel(
        'Today: 2 overdue items. 1 item due today. 3 Care coming up.',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('2 overdue items'), findsNothing);
  });

  testWidgets(
    'renders all supported foundation states without management rows',
    (tester) async {
      for (final state in GuardianTodayScreenState.values) {
        await tester.pumpWidget(
          buildSubject(
            state: state,
            careSummary: summary(overdue: 0, dueToday: 0, upcoming: 0),
          ),
        );

        expect(
          find.byKey(Key('guardian_today_orientation_${state.name}')),
          findsOneWidget,
        );
        expect(find.byType(ListTile), findsNothing);
        expect(find.text('Today'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'missing summary falls back to partial rather than inventing care',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(state: GuardianTodayScreenState.attention),
      );

      expect(
        find.byKey(const Key('guardian_today_orientation_partial')),
        findsOneWidget,
      );
      expect(find.text("We couldn't load care right now."), findsOneWidget);
    },
  );

  testWidgets('retry has an accessible 48dp target and invokes its callback', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      buildSubject(
        state: GuardianTodayScreenState.error,
        onRetry: () => retries++,
      ),
    );

    final retry = find.bySemanticsLabel('Retry');
    expect(retry, findsOneWidget);
    expect(tester.getSize(retry).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
    tester.widget<TextButton>(find.byType(TextButton)).onPressed!();
    expect(retries, 1);
  });

  testWidgets('wraps long French copy at 200% text scale without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildSubject(
        state: GuardianTodayScreenState.error,
        onRetry: () {},
        locale: const Locale('fr'),
        textScaler: TextScaler.linear(2),
      ),
    );

    expect(find.byKey(const Key('guardian_today_orientation')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stays within narrow, phone, and tablet widths', (tester) async {
    for (final width in [320.0, 390.0, 768.0]) {
      await tester.binding.setSurfaceSize(Size(width, 700));
      await tester.pumpWidget(
        buildSubject(
          state: GuardianTodayScreenState.attention,
          careSummary: summary(),
        ),
      );
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}

HealthEntry _entry(String id, {required DateTime dueDate}) => HealthEntry(
  id: id,
  petId: 'pet-1',
  name: id,
  type: HealthEntryType.other,
  frequency: HealthFrequency.daily,
  startDate: dueDate.subtract(const Duration(days: 1)),
  nextDueDate: dueDate,
  remindDaysBefore: 3,
);
