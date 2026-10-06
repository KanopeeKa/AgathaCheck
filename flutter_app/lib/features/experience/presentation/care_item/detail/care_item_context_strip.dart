import 'package:flutter/material.dart';

import 'package:pet_profile_app/features/experience/presentation/config/pet_care_primary_destinations.dart';
import 'package:pet_profile_app/features/care_taxonomy/presentation/widgets/care_family_labels.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'care_item_pet_context_tile.dart';

enum _CareItemStripChip { finished, paused }

_CareItemStripChip? careItemStripChip(HealthEntry entry) {
  final finished =
      entry.status == 'completed' || isHealthEntrySeriesClosed(entry);
  if (finished) return _CareItemStripChip.finished;
  if (entry.isPaused) return _CareItemStripChip.paused;
  return null;
}

/// Context strip: pet chip, care name, category icon, optional status chip.
class CareItemContextStrip extends StatelessWidget {
  const CareItemContextStrip({
    super.key,
    required this.entry,
    required this.pet,
  });

  final HealthEntry entry;
  final Pet pet;

  static const _stackedMaxWidth = 360.0;
  static const _largeTextScaleThreshold = 1.3;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final family = entry.careFamily ?? inferCareFamily(entry);
    final familyLabel = careFamilyLabel(l, family);
    final chip = careItemStripChip(entry);
    final chipLabel = switch (chip) {
      _CareItemStripChip.finished => l.careItemStatusFinished,
      _CareItemStripChip.paused => l.careItemPausedStatus,
      null => null,
    };

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
          child: CareFamilyIcon.forEntry(entry, showChip: false),
        );

        final chipWidget = chipLabel == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    key: const Key('care_item_context_strip_chip'),
                    label: Text(chipLabel),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    side: BorderSide.none,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: nameWidget),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CareItemPetContextTile(pet: pet),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: nameWidget),
                      const SizedBox(width: 8),
                      categoryIcon,
                    ],
                  ),
                ),
              ],
            ),
            if (chipWidget != null) chipWidget,
          ],
        );
      },
    );
  }
}
