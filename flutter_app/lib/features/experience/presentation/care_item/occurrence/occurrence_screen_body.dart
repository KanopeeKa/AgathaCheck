import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'occurrence_absence_section.dart';
import 'occurrence_complete_care_module.dart';
import 'occurrence_identity_card.dart';
import 'occurrence_next_open_module.dart';
import 'occurrence_skip_command.dart';

/// Module layout for the Care date screen (phone + wide breakpoints).
class OccurrenceScreenBody extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<OccurrenceScreenBody> createState() =>
      _OccurrenceScreenBodyState();
}

const _kOccurrenceModuleGap = SizedBox(height: 16);

class _OccurrenceScreenBodyState extends ConsumerState<OccurrenceScreenBody> {
  bool _skipBusy = false;

  bool get _scheduleActionsBusy => widget.rescheduleBusy || _skipBusy;

  Future<void> _skip() async {
    if (_skipBusy || !widget.detail.occurrence.isOpen) return;
    setState(() => _skipBusy = true);
    final l = AppLocalizations.of(context)!;
    try {
      final outcome = await runOccurrenceSkip(
        ref,
        context: context,
        detail: widget.detail,
      );
      if (outcome == null) return;
      await widget.onChanged();
      if (!mounted) return;
      switch (outcome) {
        case CareSucceeded():
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(occurrenceSkipSuccessMessage(l, widget.detail)),
              ),
            );
        case CareFailed(failure: CareNotOpenFailure()):
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l.careAlreadyUpdated)));
        case CareFailed():
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l.careCommandFailed)));
      }
    } finally {
      if (mounted) setState(() => _skipBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final identity = OccurrenceIdentityCard(
      detail: detail,
      onOpenCareDetails: widget.onOpenCareDetails,
      scheduleActionsBusy: _scheduleActionsBusy,
      onChangeDate: detail.occurrence.isOpen ? widget.onReschedule : null,
      onSkip: detail.occurrence.isOpen ? _skip : null,
    );
    final complete = OccurrenceCompleteCareModule(
      detail: detail,
      focus: widget.focus,
      onChanged: widget.onChanged,
      actionBusy: _scheduleActionsBusy,
    );
    final away = _AwayModule(
      entryId: widget.entryId,
      detail: detail,
      onChanged: widget.onChanged,
    );
    final nextOpen = OccurrenceNextOpenModule(
      detail: detail,
      petId: widget.petId,
      entryId: widget.entryId,
      onOpenCareDetails: widget.onOpenCareDetails,
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
              children: [
                identity,
                _kOccurrenceModuleGap,
                away,
                _kOccurrenceModuleGap,
                complete,
                _kOccurrenceModuleGap,
                nextOpen,
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              identity,
              _kOccurrenceModuleGap,
              away,
              _kOccurrenceModuleGap,
              if (showNext)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: complete),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: nextOpen),
                  ],
                )
              else
                complete,
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
