import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/care_recommendation.dart';
import 'care_suggestion_respond_actions.dart';
import 'suggestion_why_sheet.dart';

/// Warm-accent suggestion card for established-care rhythm proposals.
class CareSuggestionCard extends ConsumerStatefulWidget {
  const CareSuggestionCard({
    super.key,
    required this.petId,
    required this.recommendation,
  });

  final String petId;
  final CareRecommendation recommendation;

  @override
  ConsumerState<CareSuggestionCard> createState() => _CareSuggestionCardState();
}

class _CareSuggestionCardState extends ConsumerState<CareSuggestionCard> {
  bool _responding = false;

  Future<void> _respond(CareRecommendationResponseAction action) async {
    if (_responding) return;
    await CareSuggestionRespondActions.respond(
      context: context,
      ref: ref,
      petId: widget.petId,
      recommendation: widget.recommendation,
      action: action,
      canEditHealth: CareSuggestionRespondActions.canEditHealth(
        ref,
        widget.petId,
      ),
      onLoadingChanged: (loading) => setState(() => _responding = loading),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final canEditHealth = CareSuggestionRespondActions.canEditHealth(
      ref,
      widget.petId,
    );
    final recommendation = widget.recommendation;
    final cadenceSummary = l.careSuggestionCadenceSummary(
      recommendation.suggestedFrequencyInterval,
      recommendation.suggestedFrequency,
    );

    return Card(
      key: Key('care_suggestion_card_${recommendation.id}'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: AppColorTokens.warmAccentLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          key: const ValueKey('care_suggestion_group'),
          container: true,
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
                cadenceSummary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Tooltip(
                    message: canEditHealth
                        ? l.careSuggestionAccept
                        : l.careSuggestionEditForbidden,
                    child: FilledButton(
                      key: Key('care_suggestion_accept_${recommendation.id}'),
                      onPressed: _responding || !canEditHealth
                          ? null
                          : () => _respond(
                              CareRecommendationResponseAction.accept,
                            ),
                      child: _responding
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : Text(l.careSuggestionAccept),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _responding
                        ? null
                        : () => showSuggestionWhySheet(
                            context,
                            rationaleKey: recommendation.rationaleKey,
                          ),
                    child: Text(l.careSuggestionWhy),
                  ),
                  TextButton(
                    onPressed: _responding || !canEditHealth
                        ? null
                        : () => _respond(
                            CareRecommendationResponseAction.notRelevant,
                          ),
                    child: Text(l.careSuggestionNotRelevant),
                  ),
                  TextButton(
                    onPressed: _responding || !canEditHealth
                        ? null
                        : () => _respond(
                            CareRecommendationResponseAction.dismiss,
                          ),
                    child: Text(l.careSuggestionDismiss),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
