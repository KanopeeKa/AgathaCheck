import '../../../l10n/app_localizations.dart';
import 'care_command_outcome.dart';

/// Snackbar copy after a bulk stack command (FR-7, AC-E2).
String careStackSuccessMessage(
  AppLocalizations l, {
  required bool done,
  required CareCommandResult result,
  required String itemName,
}) {
  final changed = result.stackChangedCount;
  final ignored = result.ignoredIds.length;
  if (ignored == 0) {
    final changed = result.stackChangedCount;
    return done
        ? l.careBulkMarkedDoneCount(changed)
        : l.careBulkSkippedCount(changed);
  }
  return done
      ? l.careStackMarkedDonePartial(changed, ignored)
      : l.careStackSkippedPartial(changed, ignored);
}
