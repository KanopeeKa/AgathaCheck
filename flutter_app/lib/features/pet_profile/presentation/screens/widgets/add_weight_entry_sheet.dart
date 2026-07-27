import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../weight_tracking/domain/entities/weight_entry.dart';
import '../../../../weight_tracking/presentation/providers/weight_providers.dart';
import '../../controllers/weight_tracking_controller.dart';

Future<void> showAddWeightEntrySheet({
  required BuildContext context,
  required String petId,
  required WeightUnit unit,
  required WeightTrackingController controller,
}) {
  final unitLabel = weightUnitLabel(unit);
  final weightController = TextEditingController();
  final notesController = TextEditingController();
  var selectedDate = DateTime.now();
  String? weightError;

  return showModalBottomSheet(
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
              Text(
                AppLocalizations.of(ctx)!.addWeightEntry,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                      setSheetState(
                        () => selectedDate = calendarDateOnly(picked),
                      );
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    ctx,
                  )!.weightWithUnit(unitLabel),
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
                    setSheetState(
                      () => weightError = AppLocalizations.of(
                        ctx,
                      )!.weightFormatHint,
                    );
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
