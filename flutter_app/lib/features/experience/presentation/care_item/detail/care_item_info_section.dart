import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/care_taxonomy/care_taxonomy.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/people/people.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

String _careSettingLabel(AppLocalizations l, CareSetting setting) {
  return switch (setting) {
    CareSetting.home => l.careSettingHome,
    CareSetting.vet => l.careSettingVet,
    CareSetting.other => l.careSettingOther,
  };
}

String _careImportanceLabel(AppLocalizations l, CareImportance importance) {
  return switch (importance) {
    CareImportance.essential => l.careImportanceEssential,
    CareImportance.recommended => l.careImportanceRecommended,
    CareImportance.optional => l.careImportanceOptional,
  };
}

/// Care item detail rows inside the Details module (schedule owns recurrence).
class CareItemInfoSection extends ConsumerWidget {
  const CareItemInfoSection({
    super.key,
    required this.entry,
    required this.muted,
    this.section = CareItemInfoSectionPart.all,
  });

  final HealthEntry entry;
  final bool muted;
  final CareItemInfoSectionPart section;

  String? _providerLabel(Roster? roster) {
    if (entry.providerTypedName != null &&
        entry.providerTypedName!.trim().isNotEmpty) {
      return entry.providerTypedName!.trim();
    }
    final id = entry.providerContactId;
    if (id == null) return null;
    return roster?.summaryById(id)?.name;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = muted ? colorScheme.onSurfaceVariant : null;
    final family = entry.careFamily ?? inferCareFamily(entry);
    final familyLabel = careFamilyLabel(l, family);
    final rosterAsync = ref.watch(rosterProvider);

    final children = <Widget>[];

    if (section == CareItemInfoSectionPart.lead ||
        section == CareItemInfoSectionPart.all) {
      final identityLine = l.careItemDetailsIdentity(familyLabel, entry.name);
      final dosageLine = entry.primaryDosageLine;

      children.addAll([
        Semantics(
          header: true,
          label: identityLine,
          child: Text(
            identityLine,
            key: const Key('care_item_details_identity'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        if (dosageLine != null) ...[
          const SizedBox(height: 8),
          CareItemDetailRow(label: l.dosage, value: dosageLine, muted: muted),
        ],
      ]);
    }

    if (section == CareItemInfoSectionPart.trail ||
        section == CareItemInfoSectionPart.all) {
      children.add(
        rosterAsync.when(
          data: (roster) {
            final provider = _providerLabel(roster);
            if (provider == null || provider.trim().isEmpty) {
              return const SizedBox.shrink();
            }
            return CareItemDetailRow(
              label: l.careProviderLabel,
              value: provider,
              muted: muted,
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      );
      if (entry.careSetting != null) {
        children.add(
          CareItemDetailRow(
            label: l.careSettingFieldLabel,
            value: _careSettingLabel(l, entry.careSetting!),
            muted: muted,
          ),
        );
      }
      if (entry.importanceOverridden && entry.careImportance != null) {
        children.add(
          CareItemDetailRow(
            label: l.careImportanceFieldLabel,
            value: _careImportanceLabel(l, entry.careImportance!),
            muted: muted,
          ),
        );
      }
      if (entry.notes.trim().isNotEmpty) {
        children.add(
          CareItemDetailRow(
            label: l.notes,
            value: entry.notes.trim(),
            muted: muted,
          ),
        );
      }
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      key: const Key('care_item_info_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

enum CareItemInfoSectionPart { lead, trail, all }
