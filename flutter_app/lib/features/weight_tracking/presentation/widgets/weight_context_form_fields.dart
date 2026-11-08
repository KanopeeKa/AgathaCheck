import 'package:flutter/material.dart';

import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../care_intelligence/care_intelligence.dart';

/// The three weight-context fields shared by the hub settings sheet.
class WeightContextFormFields extends StatefulWidget {
  const WeightContextFormFields({
    super.key,
    required this.formKey,
    required this.initialReferenceValue,
    required this.initialReferenceAuthority,
    required this.initialManagementContext,
  });

  final GlobalKey<FormState> formKey;
  final String initialReferenceValue;
  final String? initialReferenceAuthority;
  final String initialManagementContext;

  @override
  State<WeightContextFormFields> createState() => WeightContextFormFieldsState();
}

class WeightContextFormFieldsState extends State<WeightContextFormFields> {
  String get referenceValueText => _referenceValueController.text;
  String? get referenceAuthority => _referenceAuthority;
  String get managementContextWire => _managementContext.wireValue;
  late final TextEditingController _referenceValueController;
  late String? _referenceAuthority;
  late ManagementContext _managementContext;

  @override
  void initState() {
    super.initState();
    _referenceValueController = TextEditingController(
      text: widget.initialReferenceValue,
    );
    _referenceAuthority = widget.initialReferenceAuthority;
    _managementContext = ManagementContextWire.fromWire(
      widget.initialManagementContext,
    );
  }

  @override
  void dispose() {
    _referenceValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PetFormLabeledField(
            label: l.weightReferenceValueLabel,
            subtitle: l.weightReferenceValueHelper,
            child: TextFormField(
              key: const Key('weight_settings_reference_value_field'),
              controller: _referenceValueController,
              decoration: const InputDecoration(suffixText: 'kg'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final num = double.tryParse(value);
                  if (num == null || num <= 0) {
                    return l.petInvalidWeight;
                  }
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          PetFormLabeledField(
            label: l.weightReferenceAuthorityLabel,
            child: DropdownButtonFormField<String?>(
              key: const Key('weight_settings_reference_authority_field'),
              initialValue: _referenceAuthority,
              decoration: const InputDecoration(),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l.weightReferenceAuthorityNone),
                ),
                DropdownMenuItem<String?>(
                  value: ReferenceAuthority.vetTarget.wireValue,
                  child: Text(l.weightReferenceAuthorityVetTarget),
                ),
                DropdownMenuItem<String?>(
                  value: ReferenceAuthority.guardianReference.wireValue,
                  child: Text(l.weightReferenceAuthorityGuardianReference),
                ),
                DropdownMenuItem<String?>(
                  value: ReferenceAuthority.historicalBaseline.wireValue,
                  child: Text(l.weightReferenceAuthorityHistoricalBaseline),
                ),
              ],
              onChanged: (value) => setState(() => _referenceAuthority = value),
            ),
          ),
          const SizedBox(height: 16),
          WeightManagementContextSelector(
            value: _managementContext,
            onChanged: (ctx) => setState(() => _managementContext = ctx),
          ),
        ],
      ),
    );
  }
}
