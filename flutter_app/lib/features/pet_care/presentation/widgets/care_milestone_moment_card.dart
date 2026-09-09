import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../progression/domain/entities/care_pending_moment.dart';
import '../care_milestone_copy.dart';
import '../providers/pet_care_presentation_providers.dart';

/// Warm, restrained milestone moment card for profile and dashboard slots.
class CareMilestoneMomentCard extends ConsumerStatefulWidget {
  const CareMilestoneMomentCard({
    super.key,
    required this.petId,
    required this.petName,
    required this.moment,
  });

  final String petId;
  final String petName;
  final CarePendingMoment moment;

  @override
  ConsumerState<CareMilestoneMomentCard> createState() =>
      _CareMilestoneMomentCardState();
}

class _CareMilestoneMomentCardState
    extends ConsumerState<CareMilestoneMomentCard> {
  var _acknowledged = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _acknowledgeIfNeeded());
  }

  Future<void> _acknowledgeIfNeeded() async {
    if (_acknowledged || !mounted) return;
    _acknowledged = true;
    try {
      await ref
          .read(careProgressionMomentsRepositoryProvider)
          .acknowledgePresented(
            petId: widget.petId,
            bundleId: widget.moment.bundleId,
          );
      ref.invalidate(petPendingCareMomentsProvider(widget.petId));
      ref.invalidate(petProfileCareMilestoneProvider(widget.petId));
    } catch (_) {
      _acknowledged = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      key: Key('care_milestone_moment_card_${widget.moment.bundleId}'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: AppColorTokens.petCareLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.careProgressionMilestoneTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColorTokens.petCareCareActive,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              careMilestoneMomentBody(
                l,
                petName: widget.petName,
                moment: widget.moment,
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
