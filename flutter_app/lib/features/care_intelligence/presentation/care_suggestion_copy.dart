import '../../../l10n/app_localizations.dart';
import '../domain/entities/care_recommendation.dart';

/// Localized cadence line for an Agatha suggestion.
///
/// Returns `null` when the server sends a frequency this build has no plural
/// form for, so the card omits the line instead of showing a wire token.
String? careSuggestionCadenceLabel(
  AppLocalizations l,
  CareRecommendation recommendation,
) {
  final interval = recommendation.suggestedFrequencyInterval;
  return switch (recommendation.suggestedFrequency) {
    'daily' => l.careSuggestionCadenceDaily(interval),
    'weekly' => l.careSuggestionCadenceWeekly(interval),
    'monthly' => l.careSuggestionCadenceMonthly(interval),
    'yearly' => l.careSuggestionCadenceYearly(interval),
    _ => null,
  };
}
