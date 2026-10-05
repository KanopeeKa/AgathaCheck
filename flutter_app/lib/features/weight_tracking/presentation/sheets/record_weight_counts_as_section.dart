import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/weight_fulfilment_candidates.dart';
import '../utils/weight_hub_labels.dart';

/// UI for the "Counts as" fulfilment choice in create mode.
class RecordWeightCountsAsSection extends StatelessWidget {
  const RecordWeightCountsAsSection({
    required this.candidatesAsync,
    required this.selectedOccurrenceId,
    required this.switchOn,
    required this.onSwitchChanged,
    required this.onRadioChanged,
    required this.onRetry,
    this.candidatesTimedOut = false,
    super.key,
  });

  final AsyncValue<WeightFulfilmentCandidates> candidatesAsync;
  final bool candidatesTimedOut;
  final String? selectedOccurrenceId;
  final bool switchOn;
  final ValueChanged<bool> onSwitchChanged;
  final ValueChanged<String?> onRadioChanged;
  final VoidCallback onRetry;

  static const _dontCountSentinel = '__dont_count__';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return candidatesAsync.when(
      loading: () {
        if (candidatesTimedOut) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l.weightCheckTimedOut,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(l.weightCheckingWeighIn)),
            ],
          ),
        );
      },
      error: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.weightCheckFailed),
          Text(l.weightCheckFailedWontCount),
          TextButton(onPressed: onRetry, child: Text(l.weightCheckRetry)),
        ],
      ),
      data: (data) {
        if (data.candidates.isEmpty) {
          return const SizedBox.shrink();
        }
        if (data.candidates.length == 1) {
          final c = data.candidates.first;
          final dateLabel = DateFormat.yMMMd().format(
            calendarDateOnly(c.scheduledDate),
          );
          final status = careOccurrenceStatusLabel(l, c.status);
          return Semantics(
            identifier: 'record_weight_counts_as',
            label: l.weightCountsAs(c.entryName),
            child: SwitchListTile(
              key: const Key('record_weight_counts_as'),
              title: Text(l.weightCountsAs(c.entryName)),
              subtitle: Text('$status · $dateLabel'),
              value: switchOn,
              onChanged: onSwitchChanged,
            ),
          );
        }
        return Column(
          key: const Key('record_weight_counts_as_choice'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.weightCountsAsChoiceHelp,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final c in data.candidates)
              ListTile(
                leading: Radio<String>(
                  value: c.occurrenceId,
                  groupValue: selectedOccurrenceId,
                  onChanged: onRadioChanged,
                ),
                title: Text(l.weightCountsAs(c.entryName)),
                subtitle: Text(
                  '${careOccurrenceStatusLabel(l, c.status)} · '
                  '${DateFormat.yMMMd().format(calendarDateOnly(c.scheduledDate))}',
                ),
                onTap: () => onRadioChanged(c.occurrenceId),
              ),
            ListTile(
              leading: Radio<String>(
                value: _dontCountSentinel,
                groupValue: selectedOccurrenceId,
                onChanged: onRadioChanged,
              ),
              title: Text(l.weightDontCount),
              onTap: () => onRadioChanged(_dontCountSentinel),
            ),
          ],
        );
      },
    );
  }

  static bool isDontCount(String? selected) =>
      selected == _dontCountSentinel || selected == '';

  static String? occurrenceIdForSave(String? selected) {
    if (selected == null || isDontCount(selected)) return null;
    return selected;
  }
}
