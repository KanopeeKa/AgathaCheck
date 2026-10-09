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

/// Guardian-facing title (display layer), keyed by [CareRecommendation.suggestionKey].
String careSuggestionDisplayTitle(
  AppLocalizations l,
  CareRecommendation recommendation,
) {
  return switch (recommendation.suggestionKey) {
    'weight_monitoring_rhythm' => l.careSuggestionDisplayTitleWeightMonitoringRhythm,
    'dental_review_rhythm' => l.careSuggestionDisplayTitleDentalReviewRhythm,
    'wellness_review_rhythm' => l.careSuggestionDisplayTitleWellnessReviewRhythm,
    _ => recommendation.suggestedName,
  };
}

/// One concise benefit line for the card (full detail remains in the why sheet).
String careSuggestionShortBenefit(
  AppLocalizations l,
  CareRecommendation recommendation,
) {
  return switch (recommendation.rationaleKey) {
    'careSuggestionWeightMonitoringWhy' => l.careSuggestionWeightMonitoringWhy,
    'careSuggestionDentalWhy' => l.careSuggestionDentalWhy,
    'careSuggestionWellnessWhy' => l.careSuggestionWellnessWhy,
    _ => l.careSuggestionGenericWhy,
  };
}

String careSuggestionRationaleBody(AppLocalizations l, String rationaleKey) {
  return switch (rationaleKey) {
    'careSuggestionWeightMonitoringWhy' => l.careSuggestionWeightMonitoringWhy,
    'careSuggestionDentalWhy' => l.careSuggestionDentalWhy,
    'careSuggestionWellnessWhy' => l.careSuggestionWellnessWhy,
    _ => l.careSuggestionGenericWhy,
  };
}
