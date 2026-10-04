import '../../../../l10n/app_localizations.dart';

/// Short relative label for a persisted pet-list sync time (UTC).
String petCacheRelativeTimeLabel(AppLocalizations l, DateTime syncedAtUtc) {
  final synced = syncedAtUtc.toUtc();
  final diff = DateTime.now().toUtc().difference(synced);
  if (diff.inMinutes < 1) {
    return l.petCacheRelativeJustNow;
  }
  if (diff.inHours < 1) {
    return l.petCacheRelativeMinutes(diff.inMinutes);
  }
  if (diff.inDays < 1) {
    return l.petCacheRelativeHours(diff.inHours);
  }
  return l.petCacheRelativeDays(diff.inDays);
}
