import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/care_list/care_list_collection.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/care_schedule_entries.dart';

void main() {
  testWidgets('shows care_list_today and care_list_upcoming semantics', (
    tester,
  ) async {
    final List<HealthEntry> entries = [
      scheduledEntry(id: 'due-today', name: 'Due today', dueInDays: 0),
      scheduledEntry(id: 'due-later', name: 'Due later', dueInDays: 14),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthEntriesNotifierProvider.overrideWith(
            () => _FixedEntries(entries),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareListCollection(
              entries: entries,
              source: CareCommandSource.agenda,
              petNames: const {'pet-1': 'Bella'},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier('care_list_today'), findsOneWidget);
    expect(find.bySemanticsIdentifier('care_list_upcoming'), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('care_list_card_due-today'),
      findsOneWidget,
    );
    expect(find.text('Due today'), findsOneWidget);

    await tester.tap(find.byKey(const Key('care_list_upcoming')));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsIdentifier('care_list_card_due-later'),
      findsOneWidget,
    );
  });
}

class _FixedEntries extends HealthEntriesNotifier {
  _FixedEntries(this._entries);
  final List<HealthEntry> _entries;

  @override
  Future<List<HealthEntry>> build() async => _entries;
}
