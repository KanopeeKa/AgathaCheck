import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../core/utils/calendar_date_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/care_command_outcome.dart';
import '../../application/care_item_providers.dart';

/// Postpone until / pause without an end date (D-CSM-028, UIR-12).
Future<bool?> showPostponeSheet(
  BuildContext context,
  WidgetRef ref, {
  required String entryId,
  required bool isFixedSchedule,
  required DateTime asOf,
  DateTime? initialUntil,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => PostponeSheet(
      entryId: entryId,
      isFixedSchedule: isFixedSchedule,
      asOf: asOf,
      initialUntil: initialUntil,
    ),
  );
}

class PostponeSheet extends ConsumerStatefulWidget {
  const PostponeSheet({
    super.key,
    required this.entryId,
    required this.isFixedSchedule,
    required this.asOf,
    this.initialUntil,
  });

  final String entryId;
  final bool isFixedSchedule;
  final DateTime asOf;
  final DateTime? initialUntil;

  @override
  ConsumerState<PostponeSheet> createState() => _PostponeSheetState();
}

class _PostponeSheetState extends ConsumerState<PostponeSheet> {
  late DateTime _until;
  late bool _noEndDate;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final today = calendarDateOnly(widget.asOf);
    _noEndDate = widget.initialUntil == null;
    _until = widget.initialUntil ?? today;
  }

  String _consequence(AppLocalizations l) {
    if (_noEndDate) return l.carePostponePauseConsequence;
    final date = DateFormat.yMMMd().format(_until);
    return widget.isFixedSchedule
        ? l.carePostponeUntilFixedConsequence(date)
        : l.carePostponeUntilAfterDoneConsequence(date);
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context)!;
    final outcome = await ref
        .read(careCompletionServiceProvider)
        .pausePostpone(
          entryId: widget.entryId,
          until: _noEndDate ? null : _until,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case CareSucceeded():
        Navigator.of(context).pop(true);
      case CareFailed():
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l.careCommandFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final theme = Theme.of(context);
    final today = calendarDateOnly(widget.asOf);
    final confirmLabel = _noEndDate
        ? l.carePostponeConfirmPause
        : l.carePostponeConfirmUntil;
    return Semantics(
      identifier: 'postpone_sheet',
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.carePostponeSheetTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            SwitchListTile(
              key: const Key('postpone_no_end_date'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.carePostponeNoEndDate),
              value: _noEndDate,
              onChanged: _busy
                  ? null
                  : (v) => setState(() {
                      _noEndDate = v;
                    }),
            ),
            if (!_noEndDate)
              ListTile(
                key: const Key('postpone_until_picker'),
                contentPadding: EdgeInsets.zero,
                title: Text(l.carePostponeUntilLabel),
                subtitle: Text(DateFormat.yMMMd().format(_until)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _busy
                    ? null
                    : () async {
                        final picked = await showCalendarDatePicker(
                          context: context,
                          initialDate: _until.isBefore(today) ? today : _until,
                          firstDate: today,
                          lastDate: DateTime(today.year + 5),
                          helpText: l.carePostponeUntilLabel,
                        );
                        if (picked != null) setState(() => _until = picked);
                      },
              ),
            const SizedBox(height: 8),
            Text(
              _consequence(l),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('postpone_confirm'),
              onPressed: _busy ? null : _submit,
              child: Text(confirmLabel),
            ),
          ],
        ),
      ),
    );
  }
}
