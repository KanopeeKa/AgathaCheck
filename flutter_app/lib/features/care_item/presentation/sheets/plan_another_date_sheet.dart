import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../core/utils/calendar_date_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/care_command_outcome.dart';
import '../../application/care_item_providers.dart';

/// Adds a planned occurrence (D-CSM-025) on an existing care item.
Future<bool?> showPlanAnotherDateSheet(
  BuildContext context,
  WidgetRef ref, {
  required String entryId,
  DateTime? initialDate,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) =>
        PlanAnotherDateSheet(entryId: entryId, initialDate: initialDate),
  );
}

class PlanAnotherDateSheet extends ConsumerStatefulWidget {
  const PlanAnotherDateSheet({
    super.key,
    required this.entryId,
    this.initialDate,
  });

  final String entryId;
  final DateTime? initialDate;

  @override
  ConsumerState<PlanAnotherDateSheet> createState() =>
      _PlanAnotherDateSheetState();
}

class _PlanAnotherDateSheetState extends ConsumerState<PlanAnotherDateSheet> {
  late DateTime _date;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? calendarDateOnly(DateTime.now());
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context)!;
    final outcome = await ref
        .read(careCompletionServiceProvider)
        .planAnotherDate(entryId: widget.entryId, date: _date);
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
    return Semantics(
      identifier: 'plan_another_date_sheet',
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.carePlanAnotherDate,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListTile(
              key: const Key('plan_another_date_picker'),
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
                        firstDate: today,
                        lastDate: DateTime(today.year + 5),
                        helpText: l.carePlanAnotherDate,
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('plan_another_date_confirm'),
              onPressed: _busy ? null : _submit,
              child: Text(l.carePlanAnotherDate),
            ),
          ],
        ),
      ),
    );
  }
}
