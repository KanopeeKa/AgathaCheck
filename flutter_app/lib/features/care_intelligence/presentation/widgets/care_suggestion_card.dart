import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/care_recommendation.dart';
import '../care_suggestion_copy.dart';
import '../care_suggestion_navigation.dart';
import 'agatha_recommendation_eyebrow.dart';
import 'care_suggestion_respond_actions.dart';
import 'package:pet_profile_app/core/widgets/agatha_message_card.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'suggestion_why_sheet.dart';

/// Agatha suggestion card for established-care rhythm proposals.
class CareSuggestionCard extends ConsumerStatefulWidget {
  const CareSuggestionCard({
    super.key,
    required this.petId,
    required this.recommendation,
    this.petName,
    this.petAvatar,
  });

  final String petId;
  final CareRecommendation recommendation;

  /// Names the pet in the "Why?" sheet. Supply it on every surface.
  final String? petName;

  /// Pet photo supplied by the host surface. When present the card also shows
  /// an identity row — needed where one card stands for any pet (dashboard),
  /// redundant where the surface already names the pet (pet profile).
  final Widget? petAvatar;

  @override
  ConsumerState<CareSuggestionCard> createState() => _CareSuggestionCardState();
}

class _CareSuggestionCardState extends ConsumerState<CareSuggestionCard> {
  bool _responding = false;

  String? get _petName {
    final name = widget.petName;
    return (name == null || name.isEmpty) ? null : name;
  }

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

  void _openReviewForm() {
    final l = AppLocalizations.of(context)!;
    navigateToCareSuggestionReviewForm(
      router: GoRouter.of(context),
      l: l,
      petId: widget.petId,
      recommendation: widget.recommendation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    ref.watch(allPetsIncludingOrgProvider);
    ref.watch(petListProvider);
    ref.watch(petDetailViewerContextProvider(widget.petId));
    final canEditHealth = CareSuggestionRespondActions.canEditHealth(
      ref,
      widget.petId,
    );
    final recommendation = widget.recommendation;
    final cadenceLabel = careSuggestionCadenceLabel(l, recommendation);
    final displayTitle = careSuggestionDisplayTitle(l, recommendation);
    final benefit = careSuggestionShortBenefit(l, recommendation);
    final petName = _petName;
    final eyebrowLabel =
        '${l.careSuggestionEyebrowAgatha} ${l.careSuggestionEyebrowRecommends}';

    return AgathaMessageCard(
      key: Key('care_suggestion_card_${recommendation.id}'),
      themeSuggestionActions: true,
      child: Semantics(
        identifier: 'care_suggestion_group',
        key: const ValueKey('care_suggestion_group'),
        container: true,
        explicitChildNodes: true,
        label: '$eyebrowLabel. $displayTitle',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AgathaRecommendationEyebrow(),
            if (widget.petAvatar != null && petName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  widget.petAvatar!,
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(petName, style: theme.textTheme.titleSmall),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              displayTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              benefit,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: Key('care_suggestion_why_link_${recommendation.id}'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 4,
                  ),
                  minimumSize: const Size(48, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _responding
                    ? null
                    : () => showSuggestionWhySheet(
                        context,
                        rationaleKey: recommendation.rationaleKey,
                        routineName: displayTitle,
                        petName: petName,
                        cadenceLabel: cadenceLabel,
                      ),
                child: Text(l.careSuggestionWhyLink),
              ),
            ),
            if (cadenceLabel != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cadenceLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ] else
              const SizedBox(height: 8),
            Tooltip(
              message: canEditHealth
                  ? l.careSuggestionAccept
                  : l.careSuggestionEditForbidden,
              child: FilledButton(
                key: Key('care_suggestion_accept_${recommendation.id}'),
                onPressed: _responding || !canEditHealth
                    ? null
                    : _openReviewForm,
                child: Text(l.careSuggestionAccept),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: Key('care_suggestion_later_${recommendation.id}'),
                    onPressed: _responding || !canEditHealth
                        ? null
                        : () => _respond(
                            CareRecommendationResponseAction.dismiss,
                          ),
                    child: Text(l.careSuggestionLater),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    key: Key('care_suggestion_no_thanks_${recommendation.id}'),
                    onPressed: _responding || !canEditHealth
                        ? null
                        : () => _respond(
                            CareRecommendationResponseAction.notRelevant,
                          ),
                    child: Text(l.careSuggestionNoThanks),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
