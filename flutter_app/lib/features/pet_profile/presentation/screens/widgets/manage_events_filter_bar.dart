import 'package:flutter/material.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_family_definition.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/domain/services/care_family_write.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/care_family_labels.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/care_filter_group_labels.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'manage_events_filters.dart';

/// Filter chips for the manage-events unified list.
@Deprecated('Use CollectionFilterBar via manage_events_collection_filter.dart')
class ManageEventsFilterBar extends StatelessWidget {
  const ManageEventsFilterBar({
    super.key,
    required this.filters,
    required this.onChanged,
  });

  final ManageEventsFilters filters;
  final ValueChanged<ManageEventsFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilterChipRow(
            children: [
              for (final group in CareFilterGroup.values)
                _filterGroupChip(group, careFilterGroupLabel(l, group)),
            ],
          ),
          const SizedBox(height: 8),
          _FilterChipRow(
            children: [
              for (final family in kRecurringCareFamilyPickerOptions)
                _familyChip(family, careFamilyLabel(l, family)),
            ],
          ),
          const SizedBox(height: 8),
          _FilterChipRow(
            children: [
              _statusChip(ManageEventsStatusFilter.all, l.all),
              _statusChip(ManageEventsStatusFilter.open, l.open),
              _statusChip(ManageEventsStatusFilter.closed, l.eventFilterClosed),
              _statusChip(ManageEventsStatusFilter.dueOverdue, l.dueAndOverdue),
            ],
          ),
          const SizedBox(height: 8),
          _FilterChipRow(
            children: [
              _recurringChip(ManageEventsRecurringFilter.all, l.all),
              _recurringChip(
                ManageEventsRecurringFilter.recurring,
                l.eventFilterRecurring,
              ),
              _recurringChip(
                ManageEventsRecurringFilter.oneTime,
                l.eventFilterOneTime,
              ),
              FilterChip(
                key: const Key('manage_events_show_skipped_chip'),
                label: Text(l.eventFilterShowSkipped),
                selected: filters.showSkipped,
                onSelected: (selected) =>
                    onChanged(filters.copyWith(showSkipped: selected)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _familyChip(CareFamily value, String label) {
    return FilterChip(
      key: Key('manage_events_family_${value.name}'),
      label: Text(label),
      selected: filters.isFamilySelected(value),
      onSelected: (_) => onChanged(filters.toggleFamily(value)),
    );
  }

  Widget _filterGroupChip(CareFilterGroup value, String label) {
    return FilterChip(
      key: Key('manage_events_filter_group_${value.name}'),
      label: Text(label),
      selected: filters.isFilterGroupSelected(value),
      onSelected: (_) => onChanged(filters.toggleFilterGroup(value)),
    );
  }

  Widget _statusChip(ManageEventsStatusFilter value, String label) {
    return FilterChip(
      key: Key('manage_events_status_${value.name}'),
      label: Text(label),
      selected: filters.isStatusSelected(value),
      onSelected: (_) => onChanged(filters.toggleStatus(value)),
    );
  }

  Widget _recurringChip(ManageEventsRecurringFilter value, String label) {
    return FilterChip(
      key: Key('manage_events_recurring_${value.name}'),
      label: Text(label),
      selected: filters.isRecurringSelected(value),
      onSelected: (_) => onChanged(filters.toggleRecurring(value)),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}
