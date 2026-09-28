import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../people/domain/entities/people_contact.dart';
import '../../../../people/presentation/providers/people_providers.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_item_detail_row.dart';
import '../../../../pet_profile/domain/services/care_family_inference.dart';
import '../../../../pet_profile/presentation/widgets/care_family_icon.dart';
import '../../../../pet_profile/presentation/widgets/care_family_labels.dart';
import '../../../domain/entities/health_entry.dart';

/// Care item identity rows inside the Details module (schedule owns recurrence).
class CareItemInfoSection extends ConsumerWidget {
  const CareItemInfoSection({
    super.key,
    required this.entry,
    required this.muted,
  });

  final HealthEntry entry;
  final bool muted;

  String? _providerLabel(AppLocalizations l, List<PeopleContact> contacts) {
    if (entry.providerTypedName != null &&
        entry.providerTypedName!.trim().isNotEmpty) {
      return entry.providerTypedName!.trim();
    }
    final id = entry.providerContactId;
    if (id == null) return null;
    for (final c in contacts) {
      if (c.id == id) return c.name;
    }
    return l.notSet;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = muted ? colorScheme.onSurfaceVariant : null;
    final family = entry.careFamily ?? inferCareFamily(entry);
    final contactsAsync = ref.watch(peopleContactsProvider);

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
        contactsAsync.when(
          data: (contacts) => CareItemDetailRow(
            label: l.careProviderLabel,
            value: _providerLabel(l, contacts) ?? l.notSet,
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
