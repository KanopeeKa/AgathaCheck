import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../weight_tracking/presentation/providers/weight_providers.dart';
import '../../controllers/weight_tracking_controller.dart';
import 'add_weight_entry_sheet.dart';
import 'weight_chart.dart';

/// Weight tracking body: unit toggle, chart, entry list, and footer add action.
class WeightTrackingContent extends ConsumerWidget {
  const WeightTrackingContent({
    required this.petId,
    required this.onAddEntry,
    super.key,
  });

  final String petId;
  final VoidCallback onAddEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = WeightTrackingController(ref);
    final entriesAsync = ref.watch(weightEntriesNotifierProvider(petId));
    final unit = ref.watch(weightUnitProvider(petId));
    final unitLabel = weightUnitLabel(unit);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SegmentedButton<WeightUnit>(
            segments: const [
              ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
              ButtonSegment(value: WeightUnit.lb, label: Text('lb')),
            ],
            selected: {unit},
            onSelectionChanged: (sel) =>
                controller.setWeightUnit(petId, sel.first),
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        entriesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l.errorLoadingWeightData(error.toString()),
              style: TextStyle(color: colorScheme.error),
            ),
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return _EmptyWeightState(
                onAddEntry: onAddEntry,
                addEntryLabel: l.addWeightEntry,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (entries.length >= 2)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 24, 8),
                    child: SizedBox(
                      height: 200,
                      child: WeightChart(entries: entries, unit: unit),
                    ),
                  ),
                if (entries.length >= 2) const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[entries.length - 1 - index];
                    final displayWeight =
                        '${convertWeight(entry.weight, unit).toStringAsFixed(1)} $unitLabel';
                    final dateLabel = DateFormat.yMMMd().format(entry.date);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.monitor_weight,
                          size: 20,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        displayWeight,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        dateLabel +
                            (entry.notes.isNotEmpty ? ' — ${entry.notes}' : ''),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: colorScheme.error,
                          size: 20,
                        ),
                        tooltip: l.deleteWeightEntry,
                        onPressed: () async {
                          await controller.deleteWeightEntry(petId, entry.id);
                        },
                      ),
                    );
                  },
                ),
                _AddEntryFooterButton(
                  onPressed: onAddEntry,
                  label: l.addWeightEntry,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EmptyWeightState extends StatelessWidget {
  const _EmptyWeightState({
    required this.onAddEntry,
    required this.addEntryLabel,
  });

  final VoidCallback onAddEntry;
  final String addEntryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MergeSemantics(
          child: Semantics(
            label: l.noWeightDataYet,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.scale_outlined,
                    size: 48,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.noWeightDataYet,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.tapAddEntryToStart,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _AddEntryFooterButton(onPressed: onAddEntry, label: addEntryLabel),
      ],
    );
  }
}

class _AddEntryFooterButton extends StatelessWidget {
  const _AddEntryFooterButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: FilledButton.tonalIcon(
        key: const Key('weight_tracking_add_footer'),
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 18),
        label: Text(label),
      ),
    );
  }
}

/// Opens the add-weight-entry bottom sheet for [petId].
void openAddWeightEntrySheet(
  BuildContext context,
  WidgetRef ref,
  String petId,
) {
  final unit = ref.read(weightUnitProvider(petId));
  showAddWeightEntrySheet(
    context: context,
    petId: petId,
    unit: unit,
    controller: WeightTrackingController(ref),
  );
}
