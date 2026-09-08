import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/care_recommendation.dart';
import '../providers/care_recommendations_provider.dart';
import 'suggestion_why_sheet.dart';

/// Warm-accent suggestion card for established-care rhythm proposals.
class CareSuggestionCard extends ConsumerWidget {
  const CareSuggestionCard({
    super.key,
    required this.petId,
    required this.recommendation,
  });

  final String petId;
  final CareRecommendation recommendation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    Future<void> respond(CareRecommendationResponseAction action) async {
      await ref
          .read(careIntelligenceRepositoryProvider)
          .respond(
            petId: petId,
            recommendationId: recommendation.id,
            action: action,
          );
      ref.invalidate(petCareRecommendationsProvider(petId));
      ref.invalidate(petProfileCareSuggestionProvider(petId));
      ref.invalidate(healthEntriesNotifierProvider);
    }

    return Card(
      key: Key('care_suggestion_card_${recommendation.id}'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: AppColorTokens.warmAccentLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.careSuggestionTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColorTokens.warmAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recommendation.suggestedName,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l.careSuggestionCadenceSummary(
                recommendation.suggestedFrequencyInterval,
                recommendation.suggestedFrequency,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: Key('care_suggestion_accept_${recommendation.id}'),
                  onPressed: () =>
                      respond(CareRecommendationResponseAction.accept),
                  child: Text(l.careSuggestionAccept),
                ),
                OutlinedButton(
                  onPressed: () => showSuggestionWhySheet(
                    context,
                    rationaleKey: recommendation.rationaleKey,
                  ),
                  child: Text(l.careSuggestionWhy),
                ),
                TextButton(
                  onPressed: () =>
                      respond(CareRecommendationResponseAction.notRelevant),
                  child: Text(l.careSuggestionNotRelevant),
                ),
                TextButton(
                  onPressed: () =>
                      respond(CareRecommendationResponseAction.dismiss),
                  child: Text(l.careSuggestionDismiss),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
