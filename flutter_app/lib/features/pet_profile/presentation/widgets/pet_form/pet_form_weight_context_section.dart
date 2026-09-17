import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../care_intelligence/domain/weight_provenance.dart';
import '../../../../care_intelligence/presentation/widgets/weight_management_context_selector.dart';
import '../../controllers/pet_form_controller.dart';
import 'pet_form_labeled_field.dart';

/// Weight-context capture unit for the pet profile edit form.
///
/// Surfaces `weight_reference_value`, `weight_reference_authority`, and
/// `weight_management_context` so guardians on a vet-supervised weight plan can
/// suppress false-firing weight-trend safeguards. Edit mode only.
class PetFormWeightContextSection extends StatefulWidget {
  const PetFormWeightContextSection({
    required this.controller,
    required this.onMarkDirty,
    super.key,
  });

  final PetFormController controller;
  final VoidCallback onMarkDirty;

  @override
  State<PetFormWeightContextSection> createState() =>
      _PetFormWeightContextSectionState();
}

class _PetFormWeightContextSectionState
    extends State<PetFormWeightContextSection> {
  late final TextEditingController _referenceValueController;

  @override
  void initState() {
    super.initState();
    _referenceValueController = TextEditingController(
      text: widget.controller.state.weightReferenceValue,
    );
  }

  @override
  void didUpdateWidget(covariant PetFormWeightContextSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = widget.controller.state.weightReferenceValue;
    if (_referenceValueController.text != nextValue) {
      _referenceValueController.text = nextValue;
    }
  }

  @override
  void dispose() {
    _referenceValueController.dispose();
    super.dispose();
  }

  void _updateReferenceValue(String value) {
    widget.controller.state = widget.controller.state.copyWith(
      weightReferenceValue: value,
    );
    widget.onMarkDirty();
  }

  void _updateReferenceAuthority(String? value) {
    widget.controller.state = widget.controller.state.copyWith(
      weightReferenceAuthority: value,
      clearWeightReferenceAuthority: value == null,
    );
    widget.onMarkDirty();
  }

  void _updateManagementContext(String value) {
    widget.controller.state = widget.controller.state.copyWith(
      weightManagementContext: value,
    );
    widget.onMarkDirty();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = widget.controller.state;

    final referenceValueField = PetFormLabeledField(
      label: l.weightReferenceValueLabel,
      subtitle: l.weightReferenceValueHelper,
      child: TextFormField(
        key: const Key('pet_weight_reference_value_field'),
        controller: _referenceValueController,
        decoration: const InputDecoration(suffixText: 'kg'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: _updateReferenceValue,
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
    );

    final authorityField = PetFormLabeledField(
      label: l.weightReferenceAuthorityLabel,
      child: DropdownButtonFormField<String?>(
        key: const Key('pet_weight_reference_authority_field'),
        value: state.weightReferenceAuthority,
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
        onChanged: _updateReferenceAuthority,
      ),
    );

    final managementContextField = WeightManagementContextSelector(
      value: ManagementContextWire.fromWire(state.weightManagementContext),
      onChanged: (ctx) => _updateManagementContext(ctx.wireValue),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        referenceValueField,
        const SizedBox(height: 16),
        authorityField,
        const SizedBox(height: 16),
        managementContextField,
      ],
    );
  }
}
