import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/core/widgets/form/app_form_actions_bar.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/features/weight_tracking/weight_tracking.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../widgets/weight_context_form_fields.dart';

Future<void> showWeightSettingsEditSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Pet pet,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => WeightSettingsEditSheet(pet: pet),
  );
}

class WeightSettingsEditSheet extends ConsumerStatefulWidget {
  const WeightSettingsEditSheet({super.key, required this.pet});

  final Pet pet;

  @override
  ConsumerState<WeightSettingsEditSheet> createState() =>
      _WeightSettingsEditSheetState();
}

class _WeightSettingsEditSheetState
    extends ConsumerState<WeightSettingsEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _fieldsKey = GlobalKey<WeightContextFormFieldsState>();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.weightHubSettingsEditTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: WeightContextFormFields(
                  key: _fieldsKey,
                  formKey: _formKey,
                  initialReferenceValue:
                      widget.pet.weightReferenceValue?.toString() ?? '',
                  initialReferenceAuthority:
                      widget.pet.weightReferenceAuthority,
                  initialManagementContext: widget.pet.weightManagementContext,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppFormActionsBar(
              isLoading: _saving,
              isDirty: true,
              requireDirtyToSave: false,
              onCancel: () => Navigator.of(context).pop(),
              onSave: _save,
              saveLabel: l.save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final fields = _fieldsKey.currentState;
    if (fields == null || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context)!;

    setState(() => _saving = true);
    try {
      final refText = fields.referenceValueText.trim();
      final referenceValue = refText.isEmpty ? null : double.tryParse(refText);

      await ref
          .read(petListProvider.notifier)
          .updatePetWeightContext(
            petId: widget.pet.id,
            weightReferenceValue: referenceValue,
            weightReferenceAuthority: fields.referenceAuthority,
            weightManagementContext: fields.managementContextWire,
          );
      ref.invalidate(weightOverviewProvider(widget.pet.id));
      if (mounted) {
        Navigator.of(context).pop();
        messenger.showSnackBar(SnackBar(content: Text(l.petFormPetSaved)));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l.failedToSave(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
