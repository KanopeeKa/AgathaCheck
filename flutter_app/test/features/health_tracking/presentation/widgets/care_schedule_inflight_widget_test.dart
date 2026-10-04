import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/controllers/care_schedule_controller.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../providers/health_entries_test_support.dart';

class _DelayedCompleteRepository implements HealthRepository {
  var completeCalls = 0;

  @override
  Future<HealthOccurrence> completeOccurrence(
    String entryId,
    String occurrenceId, {
    String notes = '',
    DateTime? completedOn,
    bool skipEarlierMissed = false,
  }) async {
    completeCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return testOccurrence(entryId, id: occurrenceId);
  }

  @override
  Future<List<HealthEntry>> getEntries({
    String? petId,
    HealthEntryType? type,
  }) async {
    return [testHealthEntry('e1')];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('duplicate occurrence taps are ignored while in flight', (
    tester,
  ) async {
    final repository = _DelayedCompleteRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          healthRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const _InflightHarness(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete'));
    await tester.pump();
    await tester.tap(find.text('Complete'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(repository.completeCalls, 1);
  });
}

class _InflightHarness extends ConsumerStatefulWidget {
  const _InflightHarness();

  @override
  ConsumerState<_InflightHarness> createState() => _InflightHarnessState();
}

class _InflightHarnessState extends ConsumerState<_InflightHarness> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(healthEntriesNotifierProvider.future);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: () {
          ref.read(careScheduleControllerProvider).completeOccurrence(
            'e1',
            'occ-1',
            completedOn: DateTime(2025, 1, 2),
          );
        },
        child: const Text('Complete'),
      ),
    );
  }
}
