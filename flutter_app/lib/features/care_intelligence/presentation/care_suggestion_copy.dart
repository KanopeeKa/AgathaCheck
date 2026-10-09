import '../../../core/care/care_suggestion_display_copy.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/care_recommendation.dart';

export '../../../core/care/care_suggestion_display_copy.dart';

String? careSuggestionCadenceLabel(
  AppLocalizations l,
  CareRecommendation recommendation,
) {
  return careSuggestionCadenceLabelFromWire(
    l,
    frequency: recommendation.suggestedFrequency,
    interval: recommendation.suggestedFrequencyInterval,
  );
}

String careSuggestionDisplayTitle(
  AppLocalizations l,
  CareRecommendation recommendation,
) {
  return careSuggestionDisplayTitleForKey(
    l,
    suggestionKey: recommendation.suggestionKey,
    suggestedName: recommendation.suggestedName,
  );
}

String careSuggestionShortBenefit(
  AppLocalizations l,
  CareRecommendation recommendation,
) {
  return careSuggestionShortBenefitForRationale(
    l,
    rationaleKey: recommendation.rationaleKey,
  );
}
