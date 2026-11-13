import 'package:flutter/material.dart';

import '../../../../../core/widgets/form/app_form_labeled_field.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/support_ticket_category.dart';

class SupportFormBugFields extends StatelessWidget {
  const SupportFormBugFields({
    super.key,
    required this.visible,
    required this.expectedController,
    required this.actualController,
    required this.stepsController,
    required this.frequency,
    required this.onFrequencyChanged,
  });

  final bool visible;
  final TextEditingController expectedController;
  final TextEditingController actualController;
  final TextEditingController stepsController;
  final SupportBugFrequency? frequency;
  final ValueChanged<SupportBugFrequency?> onFrequencyChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: visible
          ? Column(
              key: const Key('support_form_bug_fields'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                AppFormLabeledField(
                  label: l.supportFormExpectedLabel,
                  child: TextFormField(
                    key: const Key('support_form_expected'),
                    controller: expectedController,
                    maxLines: 3,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(),
                  ),
                ),
                const SizedBox(height: 12),
                AppFormLabeledField(
                  label: l.supportFormActualLabel,
                  child: TextFormField(
                    key: const Key('support_form_actual'),
                    controller: actualController,
                    maxLines: 3,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(),
                  ),
                ),
                const SizedBox(height: 12),
                AppFormLabeledField(
                  label: l.supportFormStepsLabel,
                  child: TextFormField(
                    key: const Key('support_form_steps'),
                    controller: stepsController,
                    maxLines: 4,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(),
                  ),
                ),
                const SizedBox(height: 12),
                AppFormLabeledField(
                  label: l.supportFormFrequencyLabel,
                  isTextField: false,
                  child: DropdownButtonFormField<SupportBugFrequency>(
                    key: const Key('support_form_frequency'),
                    value: frequency,
                    decoration: const InputDecoration(),
                    items: [
                      DropdownMenuItem(
                        value: SupportBugFrequency.always,
                        child: Text(l.supportFormFrequencyAlways),
                      ),
                      DropdownMenuItem(
                        value: SupportBugFrequency.sometimes,
                        child: Text(l.supportFormFrequencySometimes),
                      ),
                      DropdownMenuItem(
                        value: SupportBugFrequency.once,
                        child: Text(l.supportFormFrequencyOnce),
                      ),
                    ],
                    onChanged: onFrequencyChanged,
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}
