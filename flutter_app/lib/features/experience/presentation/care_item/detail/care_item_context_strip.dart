import 'package:flutter/material.dart';

import 'package:pet_profile_app/features/experience/presentation/config/pet_care_primary_destinations.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'care_item_pet_context_tile.dart';

enum _CareItemStripChip { closed, paused }

/// Visual size for pet avatar and care-family icon in the context strip row.
const double _kContextStripEndcapSize = CareItemPetContextTile.avatarSize;

_CareItemStripChip? careItemStripChip(HealthEntry entry) {
  if (entry.status == 'closed' || entry.status == 'completed') {
    return _CareItemStripChip.closed;
  }
  if (entry.isPaused) return _CareItemStripChip.paused;
  if (isHealthEntrySeriesClosed(entry)) return _CareItemStripChip.closed;
  return null;
}

String? careItemStripChipLabel(
  AppLocalizations l,
  HealthEntry entry, {
  String? careClosedReason,
}) {
  return switch (careItemStripChip(entry)) {
    _CareItemStripChip.closed => formatHealthEntryClosedStatusLabel(
      l,
      careClosedReason,
    ),
    _CareItemStripChip.paused => l.careItemPausedStatus,
    null => null,
  };
}

/// Context strip: pet chip, care name, category icon, optional status chip.
class CareItemContextStrip extends StatelessWidget {
  const CareItemContextStrip({
    super.key,
    required this.entry,
    required this.pet,
    this.careClosedReason,
  });

  final HealthEntry entry;
  final Pet pet;
  final String? careClosedReason;

  static const _stackedMaxWidth = 360.0;
  static const _largeTextScaleThreshold = 1.3;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final family = entry.careFamily ?? inferCareFamily(entry);
    final familyLabel = careFamilyLabel(l, family);
    final chipLabel = careItemStripChipLabel(
      l,
      entry,
      careClosedReason: careClosedReason,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stripWidth = constraints.maxWidth;
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final stacked =
            stripWidth <= _stackedMaxWidth ||
            textScale >= _largeTextScaleThreshold;
        final viewportWidth = MediaQuery.sizeOf(context).width;
        final useContentHeaderTitle = !PetCarePrimaryDestinations.isCompact(
          viewportWidth,
        );
        final nameStyle =
            (useContentHeaderTitle
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.titleLarge)
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                );

        final nameWidget = Semantics(
          header: true,
          label: familyLabel.isEmpty
              ? entry.name
              : '${entry.name}, $familyLabel',
          child: Text(
            entry.name,
            key: const Key('care_item_context_strip_title'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: nameStyle,
          ),
        );

        final categoryIcon = ExcludeSemantics(
          child: CareFamilyIcon.forEntry(
            entry,
            showChip: false,
            size: _kContextStripEndcapSize,
          ),
        );

        final chipWidget = chipLabel == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    container: true,
                    identifier: 'care_item_context_strip_chip',
                    child: HealthEntryStatusLabel(
                      key: const Key('care_item_context_strip_chip'),
                      text: chipLabel,
                      treatment: healthEntryLifecycleStatusTreatment(
                        entry,
                        colorScheme,
                      ),
                      compact: false,
                    ),
                  ),
                ),
              );

        if (stacked) {
          return Column(
            key: const Key('care_item_context_strip'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CareItemPetContextTile(pet: pet),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: nameWidget,
                    ),
                  ),
                  const SizedBox(width: 8),
                  categoryIcon,
                ],
              ),
              if (chipWidget != null) chipWidget,
            ],
          );
        }

        return Column(
          key: const Key('care_item_context_strip'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CareItemPetContextTile(pet: pet),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(alignment: Alignment.center, child: nameWidget),
                ),
                const SizedBox(width: 8),
                categoryIcon,
              ],
            ),
            if (chipWidget != null) chipWidget,
          ],
        );
      },
    );
  }
}
