import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/care_category_blocks/care_category_blocks_detail_section.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_form/health_entry_care_classification_labels.dart';
import 'package:pet_profile_app/features/people/people.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Care item detail rows inside the Details module (schedule owns recurrence).
class CareItemInfoSection extends ConsumerWidget {
  const CareItemInfoSection({
    super.key,
    required this.entry,
    required this.pet,
    required this.muted,
  });

  final HealthEntry entry;
  final Pet pet;
  final bool muted;

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
    final dosageLine = careItemPrimaryDosageLine(entry);
    final hasDosageRow = dosageLine != null;

    final identityLine = l.careItemDetailsIdentity(familyLabel, entry.name);

    return Column(
      key: const Key('care_item_info_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        if (hasDosageRow) ...[
          const SizedBox(height: 8),
          CareItemDetailRow(label: l.dosage, value: dosageLine!, muted: muted),
        ],
        CareCategoryBlocksDetailSection(
          entry: entry,
          pet: pet,
          muted: muted,
          skipDosageLine: hasDosageRow,
        ),
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
        if (entry.careSetting != null)
          CareItemDetailRow(
            label: l.careSettingFieldLabel,
            value: healthEntryCareSettingLabel(l, entry.careSetting!),
            muted: muted,
          ),
        if (entry.importanceOverridden && entry.careImportance != null)
          CareItemDetailRow(
            label: l.careImportanceFieldLabel,
            value: healthEntryCareImportanceLabel(l, entry.careImportance!),
            muted: muted,
          ),
        if (entry.notes.trim().isNotEmpty)
          CareItemDetailRow(
            label: l.notes,
            value: entry.notes.trim(),
            muted: muted,
          ),
      ],
    );
  }
}
