import 'package:flutter/material.dart';

import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';

import 'occurrence_absence_section.dart';
import 'occurrence_complete_care_module.dart';
import 'occurrence_identity_card.dart';
import 'occurrence_next_open_module.dart';

/// Module layout for the Care date screen (phone + wide breakpoints).
class OccurrenceScreenBody extends StatelessWidget {
  const OccurrenceScreenBody({
    super.key,
    required this.petId,
    required this.entryId,
    required this.detail,
    required this.focus,
    required this.onChanged,
    required this.onOpenCareDetails,
    required this.rescheduleBusy,
    required this.onReschedule,
  });

  final String petId;
  final String entryId;
  final OccurrenceDetail detail;
  final String? focus;
  final Future<void> Function() onChanged;
  final VoidCallback onOpenCareDetails;
  final bool rescheduleBusy;
  final VoidCallback onReschedule;

  static const _gap = SizedBox(height: 16);

  @override
  Widget build(BuildContext context) {
    final identity = OccurrenceIdentityCard(
      detail: detail,
      onOpenCareDetails: onOpenCareDetails,
    );
    final thisDate = OccurrenceCompleteCareModule(
      detail: detail,
      focus: focus,
      onChanged: onChanged,
      rescheduleBusy: rescheduleBusy,
      onReschedule: onReschedule,
    );
    final away = _AwayModule(
      entryId: entryId,
      detail: detail,
      onChanged: onChanged,
    );
    final nextOpen = OccurrenceNextOpenModule(
      detail: detail,
      petId: petId,
      entryId: entryId,
      onOpenCareDetails: onOpenCareDetails,
    );

    return CareItemDetailCanvas(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layoutWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final wide = layoutWidth >= kCareItemTwoColumnBreakpoint;
          final showNext = _nextOpenVisible(detail);

          if (!wide) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [identity, _gap, thisDate, _gap, away, _gap, nextOpen],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              identity,
              _gap,
              away,
              _gap,
              if (showNext)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: thisDate),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: nextOpen),
                  ],
                )
              else
                thisDate,
            ],
          );
        },
      ),
    );
  }

  bool _nextOpenVisible(OccurrenceDetail detail) {
    final schedule = detail.schedule;
    if (schedule == null) return false;
    return nextOpenOccurrenceAfter(
          openOccurrences: schedule.openOccurrences,
          currentId: detail.occurrence.id,
          currentDate: detail.occurrence.date,
          currentTime: detail.occurrence.time,
        ) !=
        null;
  }
}

class _AwayModule extends StatelessWidget {
  const _AwayModule({
    required this.entryId,
    required this.detail,
    required this.onChanged,
  });

  final String entryId;
  final OccurrenceDetail detail;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    if (!detail.occurrence.isOpen) return const SizedBox.shrink();
    return CareItemModule(
      child: OccurrenceAbsenceSection(
        entryId: entryId,
        detail: detail,
        onChanged: onChanged,
      ),
    );
  }
}
