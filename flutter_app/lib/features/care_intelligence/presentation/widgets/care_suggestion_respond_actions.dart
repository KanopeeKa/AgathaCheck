import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../pet_care/presentation/providers/pet_care_presentation_providers.dart';
import '../../../pet_profile/domain/services/pet_detail_actions.dart';
import '../../../pet_profile/presentation/providers/pet_detail_viewer_context_provider.dart';
import '../../data/care_intelligence_exception.dart';
import '../../domain/entities/care_recommendation.dart';
import '../providers/care_recommendations_provider.dart';

/// Accept / dismiss / not-relevant handlers for [CareSuggestionCard].
class CareSuggestionRespondActions {
  const CareSuggestionRespondActions._();

  static Future<void> respond({
    required BuildContext context,
    required WidgetRef ref,
    required String petId,
    required CareRecommendation recommendation,
    required CareRecommendationResponseAction action,
    required bool canEditHealth,
    required ValueSetter<bool> onLoadingChanged,
  }) async {
    if (!canEditHealth) {
      _showSnackBar(context, _forbiddenMessage(AppLocalizations.of(context)!));
      return;
    }

    onLoadingChanged(true);
    try {
      await ref
          .read(careIntelligenceRepositoryProvider)
          .respond(
            petId: petId,
            recommendationId: recommendation.id,
            action: action,
          );
      ref.invalidate(petCareRecommendationsProvider(petId));
      ref.invalidate(petProfileCareSuggestionProvider(petId));
      ref.invalidate(petProfileCareMilestoneProvider(petId));
      ref.invalidate(healthEntriesNotifierProvider);

      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      if (action == CareRecommendationResponseAction.accept) {
        _showSnackBar(
          context,
          l.careSuggestionRhythmAdded(recommendation.suggestedName),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        _errorMessage(AppLocalizations.of(context)!, error),
      );
    } finally {
      if (context.mounted) {
        onLoadingChanged(false);
      }
    }
  }

  static String _forbiddenMessage(AppLocalizations l) =>
      l.careSuggestionEditForbidden;

  static String _errorMessage(AppLocalizations l, Object error) {
    if (error is CareIntelligenceException && error.isForbidden) {
      return l.careSuggestionEditForbidden;
    }
    return l.careSuggestionRespondFailed;
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static bool canEditHealth(WidgetRef ref, String petId) {
    return ref
        .read(petDetailViewerContextProvider(petId))
        .can(PetDetailAction.editHealth);
  }
}
