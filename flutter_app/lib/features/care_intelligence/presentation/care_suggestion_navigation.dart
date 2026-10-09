import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../pet_profile/pet_profile.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/care_recommendation.dart';
import 'care_suggestion_copy.dart';

/// Opens the care add form so the guardian can review before accepting.
void navigateToCareSuggestionReviewForm({
  required BuildContext context,
  required AppLocalizations l,
  required String petId,
  required CareRecommendation recommendation,
}) {
  final title = careSuggestionDisplayTitle(l, recommendation);
  final query = Uri(
    queryParameters: {
      'family': recommendation.careFamily.wireValue,
      'planning': 'planned',
      'careRecommendationId': recommendation.id,
      'name': title,
      'frequency': recommendation.suggestedFrequency,
      'frequencyInterval': recommendation.suggestedFrequencyInterval.toString(),
    },
  ).query;
  context.go('/pet/$petId/care/add?$query');
}
