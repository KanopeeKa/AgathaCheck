import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/widgets/health_entry_status.dart';
import '../../../../health_tracking/presentation/widgets/pet_event_lifecycle.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_action_row.dart';
import '../../widgets/care_family_icon.dart';
import '../../widgets/care_family_labels.dart';
import '../../../domain/services/care_family_inference.dart';

/// Builds a [CareActionRow] for one open care item in the profile section.
class PetCareActionRowBuilder {
  const PetCareActionRowBuilder({
    required this.entry,
    required this.l10n,
    required this.colorScheme,
    required this.isEstablished,
    required this.trailingLabel,
    this.onMarkDone,
    this.onTap,
    this.statusLineOverride,
    this.statusTreatmentOverride,
  });

  final HealthEntry entry;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final bool isEstablished;
  final String trailingLabel;
  final VoidCallback? onMarkDone;
  final VoidCallback? onTap;
  final String? statusLineOverride;
  final HealthEntryStatusTreatment? statusTreatmentOverride;

  String _subtitle() {
    final family = entry.careFamily ?? inferCareFamily(entry);
    final familyLabel = careFamilyLabel(l10n, family);
    final cadence = formatRecurrenceSummary(l10n, entry);
    final parts = <String>[familyLabel, cadence];
    if (isEstablished) {
      parts.add(l10n.careProgressionEstablishedMarker);
    }
    return parts.join(' · ');
  }

  CareActionRow build({bool inset = false}) {
    final statusLine =
        statusLineOverride ?? formatHealthEntryStatusLine(entry, l10n);
    final statusTreatment =
        statusTreatmentOverride ??
        healthEntryStatusTreatment(entry, colorScheme);
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
      trailingLabel: trailingLabel,
      onPressed: onMarkDone == null
          ? null
          : () {
              onMarkDone!();
            },
      onTap: onTap,
    );
  }
}
