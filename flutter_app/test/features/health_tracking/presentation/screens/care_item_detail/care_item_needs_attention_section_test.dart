import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/care_item_detail/care_item_needs_attention_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/care_schedule_entries.dart';

class _Notifier extends HealthEntriesNotifier {
  @override
  Future<List<HealthEntry>> build() async => [];

  @override
  Future<void> refresh() async {}
}

void main() {
  testWidgets('CI-1 a stack lists every slot and Mark all as done sends one '
      'resolve-stack', (tester) async {
    final today = careToday();
    final entry = scheduledEntry(
      id: 'pill',
      name: 'Pill',
      fixed: true,
      frequency: HealthFrequency.daily,
      open: [
        for (var d = 2; d >= 0; d--)
          OpenOccurrence(
            id: 'slot-$d',
            date: today.subtract(Duration(days: d)),
            status: d == 0
                ? CareOccurrenceStatus.due
                : CareOccurrenceStatus.notRecorded,
            origin: CareOccurrenceOrigin.schedule,
          ),
      ],
    );
    final requests = <http.Request>[];
    final client = MockClient((r) async {
      requests.add(r);
      return http.Response(json.encode({'undo_token': 'u'}), 200);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          careItemHttpClientProvider.overrideWithValue(client),
          healthEntriesNotifierProvider.overrideWith(_Notifier.new),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: CareItemNeedsAttentionSection(
                entry: entry,
                schedule: entry.schedule!,
                muted: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var d = 0; d <= 2; d++) {
      expect(find.byKey(Key('care_item_occurrence_slot-$d')), findsOneWidget);
    }
    expect(find.text('Not recorded'), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('care_item_mark_all_done')));
    await tester.pumpAndSettle();
    expect(requests, hasLength(1));
    expect(requests.single.url.path, endsWith('/occurrences/resolve-stack'));
    final body = json.decode(requests.single.body) as Map<String, dynamic>;
    expect(body['given'], ['slot-2', 'slot-1', 'slot-0']);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('leading open slot shows Change date (UIR-21)', (tester) async {
    final today = careToday();
    final entry = scheduledEntry(
      id: 'groom',
      name: 'Grooming',
      frequency: HealthFrequency.monthly,
      open: [
        OpenOccurrence(
          id: 'slot-1',
          date: today.subtract(const Duration(days: 2)),
          status: CareOccurrenceStatus.overdue,
          origin: CareOccurrenceOrigin.schedule,
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [healthEntriesNotifierProvider.overrideWith(_Notifier.new)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CareItemNeedsAttentionSection(
              entry: entry,
              schedule: entry.schedule!,
              muted: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('care_item_occurrence_reschedule_slot-1')),
      findsOneWidget,
    );
  });
}
