/// Client-side pet list cache freshness (Package 7 / D18).
enum PetCacheFreshness {
  /// Loaded from the server in this fetch call.
  fresh,

  /// Cached data with a known sync time within the stale window (≤ 7 days).
  stale,

  /// Cached data older than the stale window, or treated as expired.
  expired,

  /// Cached data with no persisted sync timestamp (legacy cache).
  unknown,
}

const Duration petCacheStaleWindow = Duration(days: 7);

/// Classifies cache freshness for a pet list payload.
PetCacheFreshness classifyPetCacheFreshness({
  required bool fromRemoteThisCall,
  DateTime? lastSyncedAtUtc,
  DateTime? nowUtc,
}) {
  if (fromRemoteThisCall) {
    return PetCacheFreshness.fresh;
  }
  if (lastSyncedAtUtc == null) {
    return PetCacheFreshness.unknown;
  }
  final now = (nowUtc ?? DateTime.now()).toUtc();
  final synced = lastSyncedAtUtc.toUtc();
  final age = now.difference(synced);
  if (age > petCacheStaleWindow) {
    return PetCacheFreshness.expired;
  }
  return PetCacheFreshness.stale;
}
