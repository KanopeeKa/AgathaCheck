import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';

class _FakeHealthEntriesNotifier extends HealthEntriesNotifier {
  int refreshCalls = 0;

  @override
  Future<List<HealthEntry>> build() async => [];

  @override
  Future<void> refresh() async {
    refreshCalls++;
    ref.invalidateSelf();
    await future;
  }
}

void main() {
  test(
    'invalidateAllCareItemDetailCaches refetches entryPastOccurrencesProvider',
    () async {
      var pastFetchCount = 0;
      final container = ProviderContainer(
        overrides: [
          healthEntriesNotifierProvider.overrideWith(
            () => _FakeHealthEntriesNotifier(),
          ),
          entryPastOccurrencesProvider('entry-1').overrideWith((ref) async {
            pastFetchCount++;
            return [];
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(entryPastOccurrencesProvider('entry-1').future);
      expect(pastFetchCount, 1);

      final notifier =
          container.read(healthEntriesNotifierProvider.notifier)
              as _FakeHealthEntriesNotifier;
      await invalidateAllCareItemDetailCaches(container);
      expect(notifier.refreshCalls, 1);

      await container.read(entryPastOccurrencesProvider('entry-1').future);
      expect(pastFetchCount, 2);
    },
  );

  test(
    'careDataChangedProvider override invalidates past occurrences family',
    () async {
      var pastFetchCount = 0;
      final container = ProviderContainer(
        overrides: [
          healthEntriesNotifierProvider.overrideWith(
            () => _FakeHealthEntriesNotifier(),
          ),
          careDataChangedProvider.overrideWith(
            (ref) =>
                () => invalidateAllCareItemDetailCaches(ref),
          ),
          entryPastOccurrencesProvider('entry-1').overrideWith((ref) async {
            pastFetchCount++;
            return [];
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(entryPastOccurrencesProvider('entry-1').future);
      expect(pastFetchCount, 1);

      await container.read(careDataChangedProvider)();
      await container.read(entryPastOccurrencesProvider('entry-1').future);
      expect(pastFetchCount, 2);
    },
  );
}
