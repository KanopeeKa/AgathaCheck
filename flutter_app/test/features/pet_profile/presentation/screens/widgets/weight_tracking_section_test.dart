import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/weight_tracking_section.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/weight_chart.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_entry.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/providers/weight_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _FakeWeightEntriesNotifier extends WeightEntriesNotifier {
  _FakeWeightEntriesNotifier(this._entries);

  final List<WeightEntry> _entries;

  @override
  Future<List<WeightEntry>> build(String arg) async => _entries;
}

Widget _wrap(List<WeightEntry> entries) {
  return ProviderScope(
    overrides: [
      weightEntriesNotifierProvider
          .overrideWith(() => _FakeWeightEntriesNotifier(entries)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SingleChildScrollView(
          child: WeightTrackingSection(petId: 'pet-1'),
        ),
      ),
    ),
  );
}

WeightEntry _entry(String id, DateTime date, double weight) =>
    WeightEntry(id: id, petId: 'pet-1', date: date, weight: weight);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows empty state when there are no entries',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const []));
    await tester.pump();
    await tester.pump();

    // Header is always visible; expand the tile to reveal the body.
    await tester.tap(find.text('Weight Tracking'));
    await tester.pump();
    await tester.pump();

    expect(find.text('No weight data yet'), findsOneWidget);
    expect(find.byType(WeightChart), findsNothing);
  });

  testWidgets('renders the weight chart when two or more entries exist',
      (WidgetTester tester) async {
    final entries = [
      _entry('w1', DateTime(2026, 1, 1), 10.0),
      _entry('w2', DateTime(2026, 2, 1), 11.5),
      _entry('w3', DateTime(2026, 3, 1), 11.0),
    ];
    await tester.pumpWidget(_wrap(entries));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Weight Tracking'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(WeightChart), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    // Each entry is also listed (one delete button per entry row).
    expect(find.byTooltip('Delete weight entry'), findsNWidgets(3));
  });

  testWidgets('hides the chart but lists a single entry',
      (WidgetTester tester) async {
    final entries = [_entry('w1', DateTime(2026, 1, 1), 10.0)];
    await tester.pumpWidget(_wrap(entries));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Weight Tracking'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(WeightChart), findsNothing);
    expect(find.byTooltip('Delete weight entry'), findsOneWidget);
  });
}
