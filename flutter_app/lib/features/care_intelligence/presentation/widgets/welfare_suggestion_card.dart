import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/widgets/agatha_message_card.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/welfare_suggestion.dart';
import 'agatha_recommendation_eyebrow.dart';
import 'welfare_suggestion_respond_actions.dart';

/// Agatha welfare guidance card (profile subjects).
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
    final copy = _copyForSubject(l, widget.suggestion.subjectKey);

    return AgathaMessageCard(
      key: Key(copy.cardKey),
      themeSuggestionActions: true,
      child: Semantics(
        container: true,
        label: '${l.careSuggestionEyebrowAgatha}. ${copy.title}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AgathaRecommendationEyebrow(),
            Text(
              copy.categoryLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(copy.title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            FilledButton(
              key: Key(copy.recordButtonKey),
              onPressed: _loading || !widget.canRecord
                  ? null
                  : () => _onRecord(context),
              child: Text(copy.recordLabel),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                TextButton(
                  onPressed: () => _showWhy(context, copy.whyBody),
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

  void _onRecord(BuildContext context) {
    final key = widget.suggestion.subjectKey;
    if (key == 'neuter_welfare') {
      showProfileFactCaptureSheet(
        context,
        ref,
        pet: widget.pet,
        topic: ProfileFactCaptureTopic.neuter,
      );
      return;
    }
    if (key == 'microchip_welfare') {
      showProfileFactCaptureSheet(
        context,
        ref,
        pet: widget.pet,
        topic: ProfileFactCaptureTopic.chip,
      );
      return;
    }
    if (key == 'vaccination_welfare') {
      context.push(
        '/pet/${widget.pet.id}/care/add?family=vaccination&planning=unplanned',
      );
    }
  }

  _WelfareCardCopy _copyForSubject(AppLocalizations l, String subjectKey) {
    switch (subjectKey) {
      case 'neuter_welfare':
        return _WelfareCardCopy(
          cardKey: 'welfare_suggestion_card_neuter',
          recordButtonKey: 'welfare_suggestion_record_neuter',
          title: l.careWelfareNeuterTitle,
          whyBody: l.careWelfareNeuterWhy,
          recordLabel: l.careWelfareNeuterRecord,
          categoryLabel: l.profileCompletenessCategory,
        );
      case 'vaccination_welfare':
        return _WelfareCardCopy(
          cardKey: 'welfare_suggestion_card_vaccination',
          recordButtonKey: 'welfare_suggestion_record_vaccination',
          title: l.careWelfareVaccinationTitle,
          whyBody: l.careWelfareVaccinationWhy,
          recordLabel: l.careWelfareVaccinationRecord,
          categoryLabel: l.careFamilyVaccination,
        );
      case 'microchip_welfare':
      default:
        return _WelfareCardCopy(
          cardKey: 'welfare_suggestion_card_microchip',
          recordButtonKey: 'welfare_suggestion_record_microchip',
          title: l.careWelfareMicrochipTitle,
          whyBody: l.careWelfareMicrochipWhy,
          recordLabel: l.careWelfareMicrochipRecord,
          categoryLabel: l.profileCompletenessCategory,
        );
    }
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

class _WelfareCardCopy {
  const _WelfareCardCopy({
    required this.cardKey,
    required this.recordButtonKey,
    required this.title,
    required this.whyBody,
    required this.recordLabel,
    required this.categoryLabel,
  });

  final String cardKey;
  final String recordButtonKey;
  final String title;
  final String whyBody;
  final String recordLabel;
  final String categoryLabel;
}
