import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/core/widgets/agatha_message_card.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/welfare_suggestion.dart';
import 'agatha_recommendation_eyebrow.dart';
import 'welfare_suggestion_respond_actions.dart';

/// Agatha welfare guidance card (PR-07 microchip subject).
class WelfareSuggestionCard extends ConsumerStatefulWidget {
  const WelfareSuggestionCard({
    super.key,
    required this.pet,
    required this.suggestion,
    required this.canRecord,
  });

  final Pet pet;
  final WelfareSuggestion suggestion;
  final bool canRecord;

  @override
  ConsumerState<WelfareSuggestionCard> createState() =>
      _WelfareSuggestionCardState();
}

class _WelfareSuggestionCardState extends ConsumerState<WelfareSuggestionCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final title = l.careWelfareMicrochipTitle;
    final whyBody = l.careWelfareMicrochipWhy;

    return AgathaMessageCard(
      key: const Key('welfare_suggestion_card_microchip'),
      themeSuggestionActions: true,
      child: Semantics(
        container: true,
        label: '${l.careSuggestionEyebrowAgatha}. $title',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AgathaRecommendationEyebrow(),
            Text(
              l.profileCompletenessCategory,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('welfare_suggestion_record_microchip'),
              onPressed: _loading || !widget.canRecord
                  ? null
                  : () => showProfileFactCaptureSheet(
                      context,
                      ref,
                      pet: widget.pet,
                      topic: ProfileFactCaptureTopic.chip,
                    ),
              child: Text(l.careWelfareMicrochipRecord),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                TextButton(
                  onPressed: () => _showWhy(context, whyBody),
                  child: Text(l.careSuggestionWhy),
                ),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => WelfareSuggestionRespondActions.dismiss(
                          context: context,
                          ref: ref,
                          petId: widget.pet.id,
                          suggestionId: widget.suggestion.id,
                          onLoadingChanged: (v) => setState(() => _loading = v),
                        ),
                  child: Text(l.dismiss),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showWhy(BuildContext context, String body) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Text(body, style: Theme.of(ctx).textTheme.bodyMedium),
      ),
    );
  }
}
