import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/people/people.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Care item identity rows inside the Details module (schedule owns recurrence).
class CareItemInfoSection extends ConsumerWidget {
  const CareItemInfoSection({
    super.key,
    required this.entry,
    required this.muted,
  });

  final HealthEntry entry;
  final bool muted;

  String? _providerLabel(AppLocalizations l, Roster? roster) {
    if (entry.providerTypedName != null &&
        entry.providerTypedName!.trim().isNotEmpty) {
      return entry.providerTypedName!.trim();
    }
    final id = entry.providerContactId;
    if (id == null) return null;
    return roster?.summaryById(id)?.name ?? l.notSet;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = muted ? colorScheme.onSurfaceVariant : null;
    final family = entry.careFamily ?? inferCareFamily(entry);
    final rosterAsync = ref.watch(rosterProvider);

    return Column(
      key: const Key('care_item_info_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CareFamilyIcon.forEntry(entry, showChip: false),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CareItemDetailRow(
          label: l.careFamilyFieldLabel,
          value: careFamilyLabel(l, family),
          muted: muted,
        ),
        rosterAsync.when(
          data: (roster) => CareItemDetailRow(
            label: l.careProviderLabel,
            value: _providerLabel(l, roster) ?? l.notSet,
            muted: muted,
          ),
          loading: () => CareItemDetailRow(
            label: l.careProviderLabel,
            value: l.notSet,
            muted: muted,
          ),
          error: (_, __) => CareItemDetailRow(
            label: l.careProviderLabel,
            value: l.notSet,
            muted: muted,
          ),
        ),
        CareItemDetailRow(
          label: l.notes,
          value: entry.notes.isNotEmpty ? entry.notes : l.notSet,
          muted: muted,
        ),
      ],
    );
  }
}
