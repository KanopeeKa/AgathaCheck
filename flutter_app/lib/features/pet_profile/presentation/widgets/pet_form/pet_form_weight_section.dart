import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../core/weight/weight_unit_preference.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../weight_tracking/weight_tracking.dart';
import '../../controllers/pet_form_controller.dart';
import 'pet_form_labeled_field.dart';

/// Weight field for edit mode (read-only + link), or optional initial weight when adding.
class PetFormWeightSection extends ConsumerWidget {
  const PetFormWeightSection({
    super.key,
    required this.isEditing,
    required this.petId,
    required this.showWeightInput,
    required this.newWeightController,
    required this.controller,
    required this.onShowWeightInput,
    required this.onHideWeightInput,
  });

  final bool isEditing;
  final String? petId;
  final bool showWeightInput;
  final TextEditingController newWeightController;
  final PetFormController controller;
  final VoidCallback onShowWeightInput;
  final VoidCallback onHideWeightInput;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final unit = ref.watch(weightUnitPreferenceProvider);
    final unitText = unitLabel(unit);

    if (isEditing && petId != null) {
      final entriesAsync = ref.watch(weightEntriesNotifierProvider(petId!));
      return PetFormLabeledField(
        label: l.weight,
        child: entriesAsync.when(
          loading: () => const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => Text(l.petProfileNoWeightRecorded),
          data: (entries) {
            final sorted = sortWeightEntriesNewestFirst(entries);
            if (sorted.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.petProfileNoWeightRecorded,
                    key: const Key('pet_weight_readonly'),
                  ),
                  const SizedBox(height: 8),
                  _recordWeightButton(context, l),
                ],
              );
            }
            final latest = sorted.first;
            final display = formatWeight(latest.weight, unit);
            final dateLabel = DateFormat.yMMMd().format(
              calendarDateOnly(latest.date),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.petProfileWeightRow(display, dateLabel),
                  key: const Key('pet_weight_readonly'),
                ),
                const SizedBox(height: 8),
                _recordWeightButton(context, l),
              ],
            );
          },
        ),
      );
    }

    if (showWeightInput) {
      return PetFormLabeledField(
        label: l.weightTodayFieldLabelUnit(unitText),
        child: TextFormField(
          key: const Key('pet_initial_weight_field'),
          controller: newWeightController,
          decoration: InputDecoration(
            suffixText: unitText,
            suffixIcon: IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: l.removeWeightEntry,
              onPressed: onHideWeightInput,
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          onChanged: controller.setNewWeight,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final num = double.tryParse(value);
              if (num == null || num <= 0) {
                return l.petInvalidWeight;
              }
            }
            return null;
          },
        ),
      );
    }

    return PetFormLabeledField(
      label: l.weight,
      child: OutlinedButton.icon(
        key: const Key('add_weight_entry_button'),
        onPressed: onShowWeightInput,
        icon: const Icon(Icons.monitor_weight_outlined, size: 18),
        label: Text(l.addWeightEntry),
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      ),
    );
  }

  Widget _recordWeightButton(BuildContext context, AppLocalizations l) {
    return TextButton(
      key: const Key('pet_record_weight_button'),
      onPressed: () => context.push('/pet/$petId/weight'),
      child: Text(l.weightRecordAction),
    );
  }
}
