import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../core/utils/calendar_date_picker.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/foster_questionnaire_template.dart';
import '../controllers/foster_questionnaire_form_controller.dart';
import '../controllers/form_state.dart';
import '../utils/foster_questionnaire_labels.dart';

class FosterQuestionnaireProfileSection extends StatelessWidget {
  const FosterQuestionnaireProfileSection({
    super.key,
    required this.template,
    required this.state,
    required this.controller,
  });

  final FosterQuestionnaireTemplate template;
  final FosterQuestionnaireFormState state;
  final FosterQuestionnaireFormController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.fosterQuestionnaireProfileIntro,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        for (final field in template.definition.profileFields) ...[
          _ProfileField(
            field: field,
            state: state,
            controller: controller,
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.field,
    required this.state,
    required this.controller,
  });

  final FosterProfileField field;
  final FosterQuestionnaireFormState state;
  final FosterQuestionnaireFormController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final help = fosterQuestionnaireProfileFieldHelp(l, field.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fosterQuestionnaireProfileFieldLabel(l, field.id),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (help.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(help, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 8),
        switch (field.responseType) {
          'multiSelect' => _MultiSelectField(
            field: field,
            state: state,
            controller: controller,
          ),
          'singleChoice' => _SingleChoiceField(
            field: field,
            state: state,
            controller: controller,
          ),
          'numberBySpecies' => _CapacityField(
            state: state,
            controller: controller,
          ),
          'availabilityAndUnavailability' => _AvailabilityField(
            state: state,
            controller: controller,
          ),
          _ => const SizedBox.shrink(),
        },
        if (field.id == 'PF01' &&
            state.answerFor('PF01').selectedOptions.contains('OTHER')) ...[
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              labelText: l.fosterQuestionnaireOtherSpeciesNoteLabel,
            ),
            onChanged: (value) => controller.setProfileNote('PF01', value),
          ),
        ],
      ],
    );
  }
}

class _MultiSelectField extends StatelessWidget {
  const _MultiSelectField({
    required this.field,
    required this.state,
    required this.controller,
  });

  final FosterProfileField field;
  final FosterQuestionnaireFormState state;
  final FosterQuestionnaireFormController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final selected = state.answerFor(field.id).selectedOptions;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in field.options)
          Semantics(
            identifier: fosterQuestionnaireProfileSemanticsId(
              field.id,
              option.toString(),
            ),
            button: true,
            selected: selected.contains(option),
            label: fosterQuestionnaireProfileOptionLabel(l, option.toString()),
            child: FilterChip(
              label: Text(
                fosterQuestionnaireProfileOptionLabel(l, option.toString()),
              ),
              selected: selected.contains(option),
              onSelected: (_) =>
                  controller.toggleProfileOption(field.id, option.toString()),
            ),
          ),
      ],
    );
  }
}

class _SingleChoiceField extends StatelessWidget {
  const _SingleChoiceField({
    required this.field,
    required this.state,
    required this.controller,
  });

  final FosterProfileField field;
  final FosterQuestionnaireFormState state;
  final FosterQuestionnaireFormController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final selected = state.answerFor(field.id).singleOptionId;

    return Column(
      children: [
        for (final option in field.options)
          if (option is Map)
            Semantics(
              identifier: fosterQuestionnaireProfileSemanticsId(
                field.id,
                option['id']?.toString() ?? '',
              ),
              label: fosterQuestionnaireProfileOptionLabel(
                l,
                option['id']?.toString() ?? '',
              ),
              child: RadioListTile<String>(
                value: option['id']?.toString() ?? '',
                groupValue: selected,
                onChanged: (value) {
                  if (value != null) {
                    controller.toggleProfileOption(field.id, value);
                  }
                },
                title: Text(
                  fosterQuestionnaireProfileOptionLabel(
                    l,
                    option['id']?.toString() ?? '',
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _CapacityField extends StatelessWidget {
  const _CapacityField({
    required this.state,
    required this.controller,
  });

  final FosterQuestionnaireFormState state;
  final FosterQuestionnaireFormController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final species = state.selectedSpecies();
    if (species.isEmpty) {
      return Text(
        l.fosterQuestionnairePf05RequiresSpecies,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Column(
      children: [
        for (final item in species)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              identifier: fosterQuestionnaireCapacitySemanticsId(item),
              textField: true,
              label: fosterQuestionnaireCapacityLabel(l, item),
              child: TextField(
                key: Key(fosterQuestionnaireCapacitySemanticsId(item)),
                decoration: InputDecoration(
                  labelText: fosterQuestionnaireCapacityLabel(l, item),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => controller.setCapacity(item, value),
              ),
            ),
          ),
      ],
    );
  }
}

class _AvailabilityField extends StatelessWidget {
  const _AvailabilityField({
    required this.state,
    required this.controller,
  });

  final FosterQuestionnaireFormState state;
  final FosterQuestionnaireFormController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final raw = state.answerFor('PF06').value;
    String? start;
    String? end;
    if (raw is Map) {
      start = raw['start']?.toString();
      end = raw['end']?.toString();
      if (start == null && end == null && raw['availability'] is List) {
        final periods = raw['availability'] as List;
        if (periods.isNotEmpty && periods.first is Map) {
          final period = periods.first as Map;
          start = period['start']?.toString();
          end = period['end']?.toString();
        }
      }
    }

    return Column(
      children: [
        _DatePickerTile(
          semanticsId: 'foster_questionnaire_pf06_start',
          label: l.fosterQuestionnaireAvailabilityStartLabel,
          value: start,
          onPick: (date) => controller.setAvailabilityStart(
            date == null ? null : toCalendarDateString(date),
          ),
        ),
        const SizedBox(height: 8),
        _DatePickerTile(
          semanticsId: 'foster_questionnaire_pf06_end',
          label: l.fosterQuestionnaireAvailabilityEndLabel,
          value: end,
          onPick: (date) => controller.setAvailabilityEnd(
            date == null ? null : toCalendarDateString(date),
          ),
        ),
      ],
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.semanticsId,
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String semanticsId;
  final String label;
  final String? value;
  final ValueChanged<DateTime?> onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final display = value == null
        ? l.fosterQuestionnaireDateNotSet
        : formatCalendarDateDisplay(parseCalendarDate(value)!);

    return Semantics(
      identifier: semanticsId,
      button: true,
      label: label,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: Text(display),
        trailing: const Icon(Icons.calendar_today_outlined),
        onTap: () async {
          final picked = await showCalendarDatePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            helpText: label,
            initialDate: parseCalendarDate(value) ?? DateTime.now(),
          );
          onPick(picked);
        },
      ),
    );
  }
}
