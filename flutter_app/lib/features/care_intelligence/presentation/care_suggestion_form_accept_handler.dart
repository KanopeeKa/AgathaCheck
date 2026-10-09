import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/care/care_suggestion_form_accept.dart';
import '../domain/entities/care_recommendation.dart';
import '../domain/repositories/care_intelligence_repository.dart';
import 'providers/care_recommendations_provider.dart';
import '../../pet_profile/pet_profile.dart';

CareSuggestionFormAcceptHandler careIntelligenceSuggestionFormAcceptHandler() {
  return (Ref ref, CareSuggestionFormAcceptRequest request) async {
    final accepted = await ref
        .read(careIntelligenceRepositoryProvider)
        .respond(
          petId: request.petId,
          recommendationId: request.recommendationId,
          action: CareRecommendationResponseAction.accept,
          adjust: {
            'name': request.name,
            'frequency': request.frequencyWire,
            'frequency_interval': request.frequencyInterval,
          },
        );
    ref.invalidate(petCareRecommendationsProvider(request.petId));
    ref.invalidate(petProfileCareSuggestionProvider(request.petId));
    return CareSuggestionFormAcceptResult(
      healthEntryId: accepted.healthEntryId,
    );
  };
}
