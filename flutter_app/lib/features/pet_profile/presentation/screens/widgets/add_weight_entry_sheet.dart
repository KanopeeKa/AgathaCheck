import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/widgets/form/app_form_actions_bar.dart';
import '../../../../../core/widgets/form/app_form_labeled_field.dart';
import '../../../../../core/utils/calendar_date.dart';
import '../../../../../core/utils/calendar_date_picker.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../weight_tracking/domain/entities/weight_entry.dart';
import '../../../../weight_tracking/presentation/providers/weight_providers.dart';
import '../../controllers/weight_tracking_controller.dart';

typedef WeightEntrySaveCallback =
    Future<void> Function(double weightKg, DateTime date, String notes);

Future<void> showAddWeightEntrySheet({
  required BuildContext context,
  required String petId,
  required WeightUnit unit,
  required WeightTrackingController controller,
  WeightEntrySaveCallback? onSave,
}) {
  final unitLabel = weightUnitLabel(unit);
  final weightController = TextEditingController();
  final notesController = TextEditingController();
  var selectedDate = calendarDateOnly(DateTime.now());
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
              AppFormLabeledField(
                label: AppLocalizations.of(ctx)!.date,
                child: Semantics(
                  label: AppLocalizations.of(ctx)!.selectDate,
                  button: true,
                  child: InkWell(
                    onTap: () async {
                      final picked = await showCalendarDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: calendarDateOnly(DateTime.now()),
                      );
                      if (picked != null) {
                        setSheetState(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(),
                      child: Text(
                        DateFormat.yMMMd().format(
                          calendarDateOnly(selectedDate),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppFormLabeledField(
                label: AppLocalizations.of(ctx)!.weightWithUnit(unitLabel),
                subtitle: AppLocalizations.of(ctx)!.weightFormatHint,
                child: TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(errorText: weightError),
                  onChanged: (_) {
                    if (weightError != null) {
                      setSheetState(() => weightError = null);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              AppFormLabeledField(
                label: AppLocalizations.of(ctx)!.notesOptional,
                child: TextField(
                  controller: notesController,
                  decoration: const InputDecoration(),
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 20),
              AppFormActionsBar(
                isLoading: false,
                isDirty: true,
                requireDirtyToSave: false,
                onCancel: () => Navigator.pop(ctx),
                saveLabel: AppLocalizations.of(ctx)!.save,
                onSave: () async {
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

                  if (onSave != null) {
                    await onSave(
                      weightInKg,
                      calendarDateOnly(selectedDate),
                      notesController.text.trim(),
                    );
                  } else {
                    final entry = WeightEntry(
                      id: '',
                      petId: petId,
                      date: calendarDateOnly(selectedDate),
                      weight: weightInKg,
                      notes: notesController.text.trim(),
                    );

                    await controller.addWeightEntry(petId, entry);
                  }

                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}
