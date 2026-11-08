import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/form/app_form_actions_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../providers/weight_providers.dart';
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

    setState(() => _saving = true);
    try {
      final refText = fields.referenceValueText.trim();
      final referenceValue = refText.isEmpty
          ? null
          : double.tryParse(refText);
      if (refText.isNotEmpty && referenceValue == null) {
        return;
      }

      await ref.read(petListProvider.notifier).updatePetWeightContext(
        petId: widget.pet.id,
        weightReferenceValue: referenceValue,
        weightReferenceAuthority: fields.referenceAuthority,
        weightManagementContext: fields.managementContextWire,
      );
      ref.invalidate(weightOverviewProvider(widget.pet.id));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.petFormPetSaved)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.petPhotoNetworkError),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
