import 'package:flutter/material.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../../core/utils/calendar_date_picker.dart';
import '../../../../core/widgets/form/app_form_section.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_occurrence.dart';
import '../../domain/entities/recurrence_anchor.dart';
import '../../domain/services/reschedule_occurrence_preview.dart';

/// Bottom sheet to pick a new scheduled date with gap + series preview (R-C2, R-C3).
Future<DateTime?> showRescheduleOccurrenceSheet(
  BuildContext context, {
  required HealthEntry entry,
  required HealthOccurrence occurrence,
  required List<HealthOccurrence> pastOccurrences,
  DateTime? initialDate,
}) {
  final today = calendarDateOnly(DateTime.now());
  final lastClosed = lastClosedReferenceDate(entry, pastOccurrences);
  final bounds = reschedulePickerBounds(
    entry: entry,
    occurrence: occurrence,
    today: today,
    lastClosedDate: lastClosed,
  );
  var selected = calendarDateOnly(
    initialDate ?? occurrence.scheduledDate,
  );
  if (selected.isBefore(bounds.firstDate)) {
    selected = bounds.firstDate;
  }
  if (bounds.lastDate != null && selected.isAfter(bounds.lastDate!)) {
    selected = bounds.lastDate!;
  }

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return _RescheduleOccurrenceSheetBody(
        entry: entry,
        occurrence: occurrence,
        lastClosedDate: lastClosed,
        initialSelected: selected,
        firstDate: bounds.firstDate,
        lastDate: bounds.lastDate,
      );
    },
  );
}

class _RescheduleOccurrenceSheetBody extends StatefulWidget {
  const _RescheduleOccurrenceSheetBody({
    required this.entry,
    required this.occurrence,
    required this.lastClosedDate,
    required this.initialSelected,
    required this.firstDate,
    required this.lastDate,
  });

  final HealthEntry entry;
  final HealthOccurrence occurrence;
  final DateTime? lastClosedDate;
  final DateTime initialSelected;
  final DateTime firstDate;
  final DateTime? lastDate;

  @override
  State<_RescheduleOccurrenceSheetBody> createState() =>
      _RescheduleOccurrenceSheetBodyState();
}

class _RescheduleOccurrenceSheetBodyState
    extends State<_RescheduleOccurrenceSheetBody> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final today = calendarDateOnly(DateTime.now());
    final gap = computeGapPreview(
      entry: widget.entry,
      newDate: _selected,
      today: today,
      lastClosedDate: widget.lastClosedDate,
    );

    final previewLines = _previewLines(l, _selected);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.rescheduleActionLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          AppFormSection(
            title: l.completedOn,
            children: [
              Semantics(
                label: l.completedOn,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(formatCalendarDateDisplay(_selected)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            container: true,
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (gap.hasComparison)
                  Text(
                    l.rescheduleGapWarning(
                      gap.actualGapDays!,
                      gap.usualGapDays,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else if (!gap.hasPriorDose)
                  Text(
                    l.rescheduleUsualGap(gap.usualGapDays),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                if (previewLines != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    previewLines,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(l.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(l.rescheduleActionLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _previewLines(AppLocalizations l, DateTime newDate) {
    if (widget.entry.frequency == HealthFrequency.once) return null;
    if (widget.entry.recurrenceAnchor == RecurrenceAnchor.fromDueDate) {
      final dates = previewNextCalendarDates(widget.entry, newDate);
      if (dates.isEmpty) return null;
      final formatted = dates.map(formatCalendarDateMedium).join(', ');
      return l.reschedulePreviewCalendar(formatted);
    }
    final next = previewNextCompletionEstimate(widget.entry, newDate);
    if (next == null) return null;
    return l.reschedulePreviewCompletion(
      formatCalendarDateMedium(next),
      formatCalendarDateDisplay(newDate),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showCalendarDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate ?? DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selected = calendarDateOnly(picked));
    }
  }
}
