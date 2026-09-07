import 'package:flutter/material.dart';

import '../../controllers/pet_form_controller.dart';

/// Frozen MVP: pets are personal-only; org ownership selector is hidden.
class PetOwnershipSelector extends StatelessWidget {
  const PetOwnershipSelector({
    required this.controller,
    required this.onOrgIdChanged,
    this.initialOrgId,
    this.selectedOrgId,
    super.key,
  });

  final PetFormController controller;
  final String? initialOrgId;
  final String? selectedOrgId;
  final ValueChanged<String?> onOrgIdChanged;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
