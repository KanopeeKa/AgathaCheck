import '../../../l10n/app_localizations.dart';

/// Localized snackbar/dialog text for sharing mutations (review C-12.2).
///
/// Never surfaces exception class names, status codes, or backend error strings.
String sharingMutationErrorMessage(AppLocalizations l, Object error) {
  final normalized = error.toString().toLowerCase();
  if (normalized.contains('not authenticated') ||
      normalized.contains('unauthorized') ||
      normalized.contains('session expired') ||
      normalized.contains('401')) {
    return l.shareSessionExpired;
  }
  return l.shareUpdateFailed;
}
