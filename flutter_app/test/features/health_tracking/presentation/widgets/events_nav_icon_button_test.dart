import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/events_nav_icon_button.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _FakeHealthEntriesNotifier extends HealthEntriesNotifier {
  _FakeHealthEntriesNotifier(this._entries);
  final List<HealthEntry> _entries;
  @override
  Future<List<HealthEntry>> build() async => _entries;
}

HealthEntry _entry({required String id, required DateTime nextDueDate}) =>
    HealthEntry(
      id: id,
      petId: 'pet-1',
      name: 'Entry $id',
      type: HealthEntryType.medication,
      frequency: HealthFrequency.monthly,
      startDate: DateTime(2025, 1, 1),
      nextDueDate: nextDueDate,
    );

Widget _wrap(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  testWidgets('EventsNavIconButton uses alert styling when due or overdue',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      const EventsNavIconButton(),
      [
        healthEntriesNotifierProvider.overrideWith(
          () => _FakeHealthEntriesNotifier([
            _entry(
              id: 'a',
              nextDueDate: today.subtract(const Duration(days: 1)),
            ),
          ]),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.list_alt));
    final theme = Theme.of(tester.element(find.byType(EventsNavIconButton)));

    expect(icon.size, EventsNavIconButton.baseIconSize * EventsNavIconButton.alertScale);
    expect(icon.color, theme.colorScheme.error);
    expect(icon.weight, 700);
    expect(icon.fill, 1.0);
  });

  testWidgets('EventsNavIconButton uses default styling when nothing is due',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      const EventsNavIconButton(),
      [
        healthEntriesNotifierProvider.overrideWith(
          () => _FakeHealthEntriesNotifier([
            _entry(
              id: 'a',
              nextDueDate: today.add(const Duration(days: 5)),
            ),
          ]),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.list_alt));

    expect(icon.size, EventsNavIconButton.baseIconSize);
    expect(icon.color, isNull);
    expect(icon.weight, isNull);
    expect(icon.fill, isNull);
  });
}
