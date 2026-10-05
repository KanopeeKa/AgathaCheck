import 'package:flutter/material.dart';

import 'package:pet_profile_app/features/care_item/domain/care_item_schedule.dart';
import 'package:pet_profile_app/features/care_item/domain/care_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'care_item_upcoming_occurrence_row.dart';

/// Upcoming occurrences capped at 3 with expand control (FR-4).
class CareItemUpcomingGroup extends StatefulWidget {
  const CareItemUpcomingGroup({
    super.key,
    required this.entry,
    required this.schedule,
    required this.occurrences,
    required this.muted,
  });

  final HealthEntry entry;
  final CareItemSchedule schedule;
  final List<OpenOccurrence> occurrences;
  final bool muted;

  static const visibleCap = 3;

  @override
  State<CareItemUpcomingGroup> createState() => _CareItemUpcomingGroupState();
}

class _CareItemUpcomingGroupState extends State<CareItemUpcomingGroup> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (widget.occurrences.isEmpty) {
      return const SizedBox.shrink();
    }

    final hidden = widget.occurrences.length - CareItemUpcomingGroup.visibleCap;
    final visible = _expanded || hidden <= 0
        ? widget.occurrences
        : widget.occurrences.take(CareItemUpcomingGroup.visibleCap).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 24),
        CareItemSectionHeader(title: l.occurrenceZoneComingUp),
        const SizedBox(height: 8),
        for (final occ in visible)
          CareItemUpcomingOccurrenceRow(
            entry: widget.entry,
            schedule: widget.schedule,
            occurrence: occ,
            muted: widget.muted,
          ),
        if (!_expanded && hidden > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('care_item_upcoming_show_more'),
              onPressed: () => setState(() => _expanded = true),
              child: Text(l.careShowCountMore(hidden)),
            ),
          ),
        if (_expanded && hidden > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('care_item_upcoming_show_less'),
              onPressed: () => setState(() => _expanded = false),
              child: Text(l.careShowLess),
            ),
          ),
      ],
    );
  }
}
