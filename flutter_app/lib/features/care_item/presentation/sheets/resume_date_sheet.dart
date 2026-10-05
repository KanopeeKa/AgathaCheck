import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../core/utils/calendar_date_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/care_command_outcome.dart';
import '../../application/care_item_providers.dart';

/// Resume on a chosen date, defaulting to the server suggestion (D-CSM-028).
Future<bool?> showResumeDateSheet(
  BuildContext context,
  WidgetRef ref, {
  required String entryId,
  required DateTime suggestedDate,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => ResumeDateSheet(
      entryId: entryId,
      suggestedDate: suggestedDate,
    ),
  );
}

class ResumeDateSheet extends ConsumerStatefulWidget {
  const ResumeDateSheet({
    super.key,
    required this.entryId,
    required this.suggestedDate,
  });

  final String entryId;
  final DateTime suggestedDate;

  @override
  ConsumerState<ResumeDateSheet> createState() => _ResumeDateSheetState();
}

class _ResumeDateSheetState extends ConsumerState<ResumeDateSheet> {
  late DateTime _date;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _date = calendarDateOnly(widget.suggestedDate);
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context)!;
    final outcome = await ref.read(careCompletionServiceProvider).resumeSeries(
          entryId: widget.entryId,
          resumeOn: _date,
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
    return Semantics(
      identifier: 'resume_date_sheet',
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.careResumeSheetTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l.careResumeDefaultHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              key: const Key('resume_date_picker'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.careNewDateTitle),
              subtitle: Text(_date.toIso8601String().substring(0, 10)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _busy
                  ? null
                  : () async {
                      final today = calendarDateOnly(DateTime.now());
                      final picked = await showCalendarDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: today.subtract(const Duration(days: 365)),
                        lastDate: DateTime(today.year + 5),
                        helpText: l.careResumeSheetTitle,
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('resume_confirm'),
              onPressed: _busy ? null : _submit,
              child: Text(l.careItemMenuResume),
            ),
          ],
        ),
      ),
    );
  }
}
