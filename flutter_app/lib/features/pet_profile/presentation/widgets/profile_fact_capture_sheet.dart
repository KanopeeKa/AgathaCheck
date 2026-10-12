import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../core/utils/calendar_date_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pet.dart';
import '../controllers/profile_fact_capture_controller.dart';
import 'pet_form/pet_form_labeled_field.dart';
import 'pet_form/pet_form_neutered_section.dart';

enum ProfileFactCaptureTopic { neuter, chip }

Future<void> showProfileFactCaptureSheet(
  BuildContext context,
  WidgetRef ref, {
  required Pet pet,
  required ProfileFactCaptureTopic topic,
}) async {
  final l = AppLocalizations.of(context)!;
  final title = topic == ProfileFactCaptureTopic.neuter
      ? l.profileFactCaptureNeuterTitle
      : l.profileFactCaptureChipTitle;

  PetNeuterSelection selection = PetNeuterSelection.unknown;
  DateTime? neuteredDate;
  final chipController = TextEditingController(text: pet.chipId);
  var saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> onSave() async {
            if (saving) return;
            if (topic == ProfileFactCaptureTopic.chip &&
                selection == PetNeuterSelection.yes &&
                chipController.text.trim().isEmpty) {
              return;
            }
            setState(() => saving = true);
            try {
              final controller = ProfileFactCaptureController(ref);
              if (topic == ProfileFactCaptureTopic.neuter) {
                await controller.saveNeuterCapture(
                  pet,
                  selection,
                  neuteredDate: neuteredDate,
                );
              } else {
                await controller.saveChipCapture(
                  pet,
                  selection,
                  chipId: chipController.text,
                );
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            } finally {
              if (ctx.mounted) setState(() => saving = false);
            }
          }

          return Padding(
            key: const Key('profile_fact_capture_sheet'),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 12),
                SegmentedButton<PetNeuterSelection>(
                  segments: [
                    ButtonSegment(
                      value: PetNeuterSelection.yes,
                      label: Text(l.petNeuterYes),
                    ),
                    ButtonSegment(
                      value: PetNeuterSelection.no,
                      label: Text(l.petNeuterNo),
                    ),
                    ButtonSegment(
                      value: PetNeuterSelection.unknown,
                      label: Text(l.petNeuterUnknown),
                    ),
                  ],
                  selected: {selection},
                  onSelectionChanged: (values) {
                    setState(() => selection = values.first);
                  },
                ),
                if (topic == ProfileFactCaptureTopic.neuter &&
                    selection == PetNeuterSelection.yes) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    key: const Key('profile_fact_capture_neuter_date'),
                    onTap: () async {
                      final initial =
                          neuteredDate ?? calendarDateOnly(DateTime.now());
                      final picked = await showCalendarDatePicker(
                        context: ctx,
                        initialDate: initial,
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => neuteredDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l.date,
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        neuteredDate != null
                            ? formatCalendarDateMedium(neuteredDate!)
                            : l.petFormSelectDate,
                      ),
                    ),
                  ),
                ],
                if (topic == ProfileFactCaptureTopic.chip &&
                    selection == PetNeuterSelection.yes) ...[
                  const SizedBox(height: 12),
                  PetFormLabeledField(
                    label: l.idMicrochip,
                    child: TextField(
                      key: const Key('profile_fact_capture_chip_id'),
                      controller: chipController,
                      decoration: const InputDecoration(),
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('profile_fact_capture_save'),
                  onPressed: saving ? null : onSave,
                  child: Text(l.save),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
