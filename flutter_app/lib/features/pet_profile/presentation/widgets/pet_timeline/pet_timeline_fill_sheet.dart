import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/pet_timeline_segment.dart';
import '../../providers/pet_timeline_providers.dart';

Future<void> showPetTimelineFillSheet(
  BuildContext context,
  WidgetRef ref, {
  required String petId,
  required String petName,
  String? initialStartDate,
  String? initialEndDate,
  PetTimelineSegment? existingEntry,
}) async {
  final l = AppLocalizations.of(context)!;
  final isEdit = existingEntry != null;
  final titleController = TextEditingController(
    text: existingEntry?.title ?? '',
  );
  final descriptionController = TextEditingController(
    text: existingEntry?.description ?? '',
  );
  final startController = TextEditingController(
    text: initialStartDate ?? existingEntry?.startDate ?? '',
  );
  final endController = TextEditingController(
    text: initialEndDate ?? existingEntry?.endDate ?? '',
  );
  final formKey = GlobalKey<FormState>();

  Future<void> pickDate(TextEditingController controller) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? l.editEntry : l.petTimelineFillTitle(petName),
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('timeline_fill_title'),
                controller: titleController,
                decoration: InputDecoration(
                  labelText: l.petTimelineFillTitleLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l.petTimelineFillTitleRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('timeline_fill_description'),
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: l.petTimelineFillDescriptionLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('timeline_fill_start_date'),
                controller: startController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: l.petTimelineFillStartDateLabel,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                onTap: () => pickDate(startController),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l.petTimelineFillStartDateRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('timeline_fill_end_date'),
                controller: endController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: l.petTimelineFillEndDateLabel,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                onTap: () => pickDate(endController),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('timeline_fill_submit'),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    final end = endController.text.trim();
                    if (isEdit) {
                      await updatePetTimelineManualEntry(
                        ref,
                        petId,
                        existingEntry.id,
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        startDate: startController.text.trim(),
                        endDate: end.isEmpty ? null : end,
                      );
                    } else {
                      await createPetTimelineManualEntry(
                        ref,
                        petId,
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        startDate: startController.text.trim(),
                        endDate: end.isEmpty ? null : end,
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(l.petTimelineFillError)),
                      );
                    }
                  }
                },
                child: Text(l.save),
              ),
            ],
          ),
        ),
      );
    },
  );

  titleController.dispose();
  descriptionController.dispose();
  startController.dispose();
  endController.dispose();
}
