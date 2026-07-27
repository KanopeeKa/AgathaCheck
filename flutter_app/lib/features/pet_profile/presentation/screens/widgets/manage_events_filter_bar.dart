import 'package:flutter/material.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'manage_events_filters.dart';

/// Filter chips for the manage-events unified list.
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
              _typeChip(ManageEventsTypeFilter.all, l.all),
              _typeChip(ManageEventsTypeFilter.medication, l.medication),
              _typeChip(ManageEventsTypeFilter.preventive, l.preventive),
              _typeChip(ManageEventsTypeFilter.vetVisit, l.vetVisit),
              _typeChip(ManageEventsTypeFilter.other, l.other),
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

  Widget _typeChip(ManageEventsTypeFilter value, String label) {
    return FilterChip(
      key: Key('manage_events_type_${value.name}'),
      label: Text(label),
      selected: filters.type == value,
      onSelected: (_) => onChanged(filters.copyWith(type: value)),
    );
  }

  Widget _statusChip(ManageEventsStatusFilter value, String label) {
    return FilterChip(
      key: Key('manage_events_status_${value.name}'),
      label: Text(label),
      selected: filters.status == value,
      onSelected: (_) => onChanged(filters.copyWith(status: value)),
    );
  }

  Widget _recurringChip(ManageEventsRecurringFilter value, String label) {
    return FilterChip(
      key: Key('manage_events_recurring_${value.name}'),
      label: Text(label),
      selected: filters.recurring == value,
      onSelected: (_) => onChanged(filters.copyWith(recurring: value)),
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
