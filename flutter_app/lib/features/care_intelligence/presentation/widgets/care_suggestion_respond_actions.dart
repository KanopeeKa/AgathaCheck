import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/core/experience/app_experience.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_viewer_role.dart';
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
      final apiId = switch (action) {
        CareRecommendationResponseAction.accept ||
        CareRecommendationResponseAction.adjust =>
          recommendation.healthEntryId ?? recommendation.id,
        CareRecommendationResponseAction.dismiss ||
        CareRecommendationResponseAction.notRelevant => recommendation.id,
      };
      await ref
          .read(careIntelligenceRepositoryProvider)
          .respond(petId: petId, recommendationId: apiId, action: action);
      ref.invalidate(petCareRecommendationsProvider(petId));
      ref.invalidate(petProfileCareSuggestionProvider(petId));
      unawaited(ref.read(healthEntriesNotifierProvider.notifier).refresh());

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
    if (ref
        .read(petDetailViewerContextProvider(petId))
        .can(PetDetailAction.editHealth)) {
      return true;
    }
    final pet = ref
        .read(petListProvider)
        .valueOrNull
        ?.where((p) => p.id == petId)
        .firstOrNull;
    if (pet == null) return false;
    final role = PetViewerRoleResolver.resolve(
      pet: pet,
      experience: AppExperience.petCare,
    );
    return PetDetailActions.canEditHealth(pet: pet, role: role);
  }
}
