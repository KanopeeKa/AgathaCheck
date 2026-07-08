import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/foster_placement.dart';

/// Body content when a pet has an active foster placement.
class FosterPlacementActiveContent extends StatelessWidget {
  const FosterPlacementActiveContent({
    super.key,
    required this.l,
    required this.theme,
    required this.placement,
    required this.onStartAdoption,
    required this.onEnd,
    required this.onCompleteConditions,
    required this.onCancelAdoption,
  });

  final AppLocalizations l;
  final ThemeData theme;
  final FosterPlacement placement;
  final VoidCallback onStartAdoption;
  final VoidCallback onEnd;
  final VoidCallback onCompleteConditions;
  final VoidCallback onCancelAdoption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (placement.startDate != null) ...[
          Text(
            l.fosterPlacementStartDate(
              DateFormat.yMMMd().format(placement.startDate!),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (placement.adoptionConditions.isNotEmpty) ...[
          Text(l.adoptionConditions, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(placement.adoptionConditions),
          const SizedBox(height: 8),
        ],
        if (placement.isInProgress) ...[
          OutlinedButton.icon(
            key: const Key('start_adoption_button'),
            onPressed: onStartAdoption,
            icon: const Icon(Icons.favorite_border, size: 18),
            label: Text(l.startAdoption),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('end_foster_placement_button'),
            onPressed: onEnd,
            icon: const Icon(Icons.event_busy, size: 18),
            label: Text(l.endFosterPlacement),
          ),
        ],
        if (placement.isPendingConditions) ...[
          OutlinedButton.icon(
            key: const Key('complete_adoption_conditions_button'),
            onPressed: onCompleteConditions,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text(l.markAdoptionConditionsMet),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onCancelAdoption,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: Text(l.cancelAdoption),
          ),
        ],
        if (placement.isWaitingAdoption) ...[
          Text(
            l.waitingAdoptionConfirmation,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onCancelAdoption,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: Text(l.cancelAdoption),
          ),
        ],
      ],
    );
  }
}
