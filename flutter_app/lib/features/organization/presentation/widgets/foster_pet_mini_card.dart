import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/presentation/utils/ownership_accent.dart';
import '../../domain/entities/foster_placement.dart';

String localizedPlacementStatus(AppLocalizations l, FosterPlacement placement) {
  if (placement.isPending) return l.fosterPlacementPending;
  if (placement.isInProgress) return l.fosterPlacementInProgress;
  if (placement.isWaitingAdoption) return l.waitingAdoptionConfirmation;
  if (placement.isPendingConditions) return l.pendingAdoptionConditions;
  if (placement.isAdopted) return l.transferTypeAdoption;
  return l.fosterPlacementNotInFosterShort;
}

String localizedPlacementOutcome(AppLocalizations l, String outcome) {
  switch (outcome) {
    case 'adopted':
      return l.placementOutcomeAdopted;
    case 'passed_away':
      return l.placementOutcomePassedAway;
    case 'in_foster_elsewhere':
      return l.placementOutcomeElsewhere;
    default:
      return l.placementOutcomeNotInFoster;
  }
}

class FosterPetMiniCard extends StatelessWidget {
  const FosterPetMiniCard({
    super.key,
    required this.petName,
    required this.statusLabel,
    this.startDate,
    this.outcomeLabel,
    this.stripColor,
    this.onTap,
  });

  final String petName;
  final String statusLabel;
  final DateTime? startDate;
  final String? outcomeLabel;
  final Color? stripColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strip = stripColor ?? fosterOwnershipAccentColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: strip,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.pets,
                              size: 14,
                              color: strip,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                petName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (startDate != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            DateFormat.yMMMd().format(startDate!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (outcomeLabel != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            outcomeLabel!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
