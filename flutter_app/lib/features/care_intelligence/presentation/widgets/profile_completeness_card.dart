import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/core/widgets/agatha_message_card.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/profile_completeness_kind.dart';
import '../profile_completeness_actions.dart';
import 'agatha_recommendation_eyebrow.dart';
import 'profile_completeness_why_sheet.dart';

/// Agatha shell for a single profile completeness prompt (neuter or chip).
class ProfileCompletenessCard extends ConsumerWidget {
  const ProfileCompletenessCard({
    super.key,
    required this.pet,
    required this.kind,
    required this.canRecord,
  });

  final Pet pet;
  final ProfileCompletenessKind kind;
  final bool canRecord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final title = switch (kind) {
      ProfileCompletenessKind.neuter => l.profilePromptNeuterMissing,
      ProfileCompletenessKind.chip => l.profilePromptChipMissing,
    };
    final key = switch (kind) {
      ProfileCompletenessKind.neuter => const Key(
        'profile_completeness_card_neuter',
      ),
      ProfileCompletenessKind.chip => const Key(
        'profile_completeness_card_chip',
      ),
    };
    final actions = ProfileCompletenessActions(ref);

    return AgathaMessageCard(
      key: key,
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
              key: Key('profile_fact_capture_record_${kind.name}'),
              onPressed: canRecord
                  ? () => showProfileFactCaptureSheet(
                      context,
                      ref,
                      pet: pet,
                      topic: kind == ProfileCompletenessKind.neuter
                          ? ProfileFactCaptureTopic.neuter
                          : ProfileFactCaptureTopic.chip,
                    )
                  : null,
              child: Text(l.profileFactCaptureRecord),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                TextButton(
                  onPressed: () =>
                      showProfileCompletenessWhySheet(context, kind: kind),
                  child: Text(l.careSuggestionWhy),
                ),
                TextButton(
                  onPressed: () => actions.hidePrompt(pet, kind),
                  child: Text(l.profileCompletenessNotForMyPet),
                ),
                TextButton(
                  onPressed: () => actions.hidePrompt(pet, kind),
                  child: Text(l.dismiss),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
