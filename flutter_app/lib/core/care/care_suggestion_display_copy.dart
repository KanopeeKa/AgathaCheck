import '../../l10n/app_localizations.dart';

/// Localized cadence line for an Agatha suggestion.
String? careSuggestionCadenceLabelFromWire(
  AppLocalizations l, {
  required String frequency,
  required int interval,
}) {
  return switch (frequency) {
    'daily' => l.careSuggestionCadenceDaily(interval),
    'weekly' => l.careSuggestionCadenceWeekly(interval),
    'monthly' => l.careSuggestionCadenceMonthly(interval),
    'yearly' => l.careSuggestionCadenceYearly(interval),
    _ => null,
  };
}

String careSuggestionDisplayTitleForKey(
  AppLocalizations l, {
  required String suggestionKey,
  required String suggestedName,
}) {
  return switch (suggestionKey) {
    'weight_monitoring_rhythm' =>
      l.careSuggestionDisplayTitleWeightMonitoringRhythm,
    'dental_review_rhythm' => l.careSuggestionDisplayTitleDentalReviewRhythm,
    'wellness_review_rhythm' =>
      l.careSuggestionDisplayTitleWellnessReviewRhythm,
    _ => suggestedName,
  };
}

String careSuggestionShortBenefitForRationale(
  AppLocalizations l, {
  required String rationaleKey,
}) {
  return careSuggestionRationaleBody(l, rationaleKey);
}

String careSuggestionRationaleBody(AppLocalizations l, String rationaleKey) {
  return switch (rationaleKey) {
    'careSuggestionWeightMonitoringWhy' => l.careSuggestionWeightMonitoringWhy,
    'careSuggestionDentalWhy' => l.careSuggestionDentalWhy,
    'careSuggestionWellnessWhy' => l.careSuggestionWellnessWhy,
    _ => l.careSuggestionGenericWhy,
  };
}
