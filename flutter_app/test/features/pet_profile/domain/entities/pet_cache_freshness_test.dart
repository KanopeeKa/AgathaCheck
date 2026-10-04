import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_cache_freshness.dart';

void main() {
  final anchor = DateTime.utc(2026, 1, 15, 12);

  test('remote fetch is always fresh', () {
    expect(
      classifyPetCacheFreshness(
        fromRemoteThisCall: true,
        lastSyncedAtUtc: null,
        nowUtc: anchor,
      ),
      PetCacheFreshness.fresh,
    );
  });

  test('missing timestamp is unknown', () {
    expect(
      classifyPetCacheFreshness(
        fromRemoteThisCall: false,
        lastSyncedAtUtc: null,
        nowUtc: anchor,
      ),
      PetCacheFreshness.unknown,
    );
  });

  test('cache within 7 days is stale', () {
    expect(
      classifyPetCacheFreshness(
        fromRemoteThisCall: false,
        lastSyncedAtUtc: anchor.subtract(const Duration(days: 7)),
        nowUtc: anchor,
      ),
      PetCacheFreshness.stale,
    );
  });

  test('cache older than 7 days is expired', () {
    expect(
      classifyPetCacheFreshness(
        fromRemoteThisCall: false,
        lastSyncedAtUtc: anchor.subtract(const Duration(days: 7, hours: 1)),
        nowUtc: anchor,
      ),
      PetCacheFreshness.expired,
    );
  });
}
