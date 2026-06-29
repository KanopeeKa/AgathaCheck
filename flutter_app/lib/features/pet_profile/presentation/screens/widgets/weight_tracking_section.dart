import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../weight_tracking/domain/entities/weight_entry.dart';
import '../../../../weight_tracking/presentation/providers/weight_providers.dart';
import '../../controllers/weight_tracking_controller.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/utils/calendar_date.dart';
import 'package:intl/intl.dart';
import 'weight_chart.dart';

class WeightTrackingSection extends ConsumerWidget {
  const WeightTrackingSection({required this.petId, super.key});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = WeightTrackingController(ref);
    final entriesAsync = ref.watch(weightEntriesNotifierProvider(petId));
    final unit = ref.watch(weightUnitProvider(petId));
    final unitLabel = weightUnitLabel(unit);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: Icon(Icons.monitor_weight, color: colorScheme.primary),
          title: Text(l.weightTracking,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SegmentedButton<WeightUnit>(
                    segments: const [
                      ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                      ButtonSegment(value: WeightUnit.lb, label: Text('lb')),
                    ],
                    selected: {unit},
                    onSelectionChanged: (sel) => controller.setWeightUnit(petId, sel.first),
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: l.addWeightEntry,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _showAddWeightSheet(context, ref, unit, unitLabel, controller),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l.addWeightEntry),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            entriesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.errorLoadingWeightData(error.toString()),
                    style: TextStyle(color: colorScheme.error)),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.scale_outlined, size: 48,
                            color: colorScheme.outline),
                        const SizedBox(height: 8),
                        Text(l.noWeightDataYet,
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(l.tapAddEntryToStart,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.outline)),
                      ],
                    ),
                  );
                }

                return Column(
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
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            child: Icon(Icons.monitor_weight, size: 20,
                                color: colorScheme.onPrimaryContainer),
                          ),
                          title: Text('${convertWeight(entry.weight, unit).toStringAsFixed(1)} $unitLabel',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            DateFormat.yMMMd().format(entry.date) +
                                (entry.notes.isNotEmpty ? ' — ${entry.notes}' : ''),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
                            tooltip: AppLocalizations.of(context)!.deleteWeightEntry,
                            onPressed: () async {
                              await controller.deleteWeightEntry(petId, entry.id);
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWeightSheet(BuildContext context, WidgetRef ref, WeightUnit unit, String unitLabel, WeightTrackingController controller) {
    final weightController = TextEditingController();
    final notesController = TextEditingController();
    var selectedDate = DateTime.now();
    String? weightError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final theme = Theme.of(ctx);
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AppLocalizations.of(ctx)!.addWeightEntry,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Semantics(
                  label: 'Select date for weight entry',
                  button: true,
                  child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDate = calendarDateOnly(picked));
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(ctx)!.date,
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: const OutlineInputBorder(),
                    ),
                    child: Text(DateFormat.yMMMd().format(selectedDate)),
                  ),
                ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(ctx)!.weightWithUnit(unitLabel),
                    prefixIcon: const Icon(Icons.monitor_weight),
                    border: const OutlineInputBorder(),
                    helperText: AppLocalizations.of(ctx)!.weightFormatHint,
                    errorText: weightError,
                  ),
                  onChanged: (_) {
                    if (weightError != null) {
                      setSheetState(() => weightError = null);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(ctx)!.notesOptional,
                    prefixIcon: const Icon(Icons.notes),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    final weightText = weightController.text.trim();
                    final inputWeight = double.tryParse(weightText);
                    if (inputWeight == null || inputWeight <= 0) {
                      setSheetState(() =>
                          weightError = AppLocalizations.of(ctx)!.weightFormatHint);
                      return;
                    }

                    final weightInKg = convertToKg(inputWeight, unit);

                    final entry = WeightEntry(
                      id: '',
                      petId: petId,
                      date: selectedDate,
                      weight: weightInKg,
                      notes: notesController.text.trim(),
                    );

                    await controller.addWeightEntry(petId, entry);

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(AppLocalizations.of(ctx)!.save),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
