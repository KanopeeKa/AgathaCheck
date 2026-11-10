import 'package:flutter/material.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';

/// Builds a [CareActionRow] for one open care item in the profile section.
class PetCareActionRowBuilder {
  const PetCareActionRowBuilder({
    required this.entry,
    required this.l10n,
    required this.colorScheme,
    required this.isEstablished,
    this.onMarkDone,
    this.onTap,
    this.statusLineOverride,
    this.statusTreatmentOverride,
    this.subtitlePetNamePrefix,
    this.rowSemanticsIdentifier,
  });

  final HealthEntry entry;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final bool isEstablished;
  final VoidCallback? onMarkDone;
  final VoidCallback? onTap;
  final String? statusLineOverride;
  final HealthEntryStatusTreatment? statusTreatmentOverride;

  /// When set (all-pets Care events list), prefixes `category · cadence` (R-026).
  final String? subtitlePetNamePrefix;
  final String? rowSemanticsIdentifier;

  String _subtitle() {
    final family = entry.careFamily ?? inferCareFamily(entry);
    final familyLabel = careFamilyLabel(l10n, family);
    final cadence = formatRecurrenceSummary(l10n, entry);
    final parts = <String>[
      if (subtitlePetNamePrefix != null && subtitlePetNamePrefix!.isNotEmpty)
        subtitlePetNamePrefix!,
      familyLabel,
      cadence,
    ];
    if (isEstablished) {
      parts.add(l10n.careProgressionEstablishedMarker);
    }
    return parts.join(' · ');
  }

  CareActionRow build({bool inset = false}) {
    final lifecycleRow = healthEntryUsesLifecycleListRow(entry);
    final statusLine =
        statusLineOverride ??
        (lifecycleRow
            ? formatHealthEntryLifecycleStatusLabel(entry, l10n)
            : formatHealthEntryStatusLine(entry, l10n));
    final statusTreatment =
        statusTreatmentOverride ??
        (lifecycleRow
            ? healthEntryLifecycleStatusTreatment(entry, colorScheme)
            : healthEntryStatusTreatment(entry, colorScheme));
    final semanticLabel = '${entry.name}, $statusLine';

    return CareActionRow(
      key: Key('pet_care_action_${entry.id}'),
      inset: inset,
      title: entry.name,
      subtitle: _subtitle(),
      statusLabel: statusLine,
      statusTreatment: statusTreatment,
      semanticLabel: semanticLabel,
      leading: CareFamilyIcon.forEntry(entry),
      onPressed: onMarkDone,
      markDoneKey: Key('pet_care_action_done_${entry.id}'),
      markDoneSemanticLabel: l10n.careMarkDoneLabel(entry.name),
      markDoneSemanticsIdentifier: 'pet_care_action_done_${entry.id}',
      rowSemanticsIdentifier:
          rowSemanticsIdentifier ?? 'care_agenda_row_${entry.id}',
      onTap: onTap,
    );
  }
}
