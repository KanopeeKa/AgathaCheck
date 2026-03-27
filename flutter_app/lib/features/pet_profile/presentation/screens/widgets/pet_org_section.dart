import 'package:flutter/material.dart';
import '../../../../../../l10n/app_localizations.dart';

class PetOrgSection extends StatelessWidget {
  final int? selectedOrgId;
  final List<Map<String, dynamic>> orgs;
  final ValueChanged<int?> onChanged;

  const PetOrgSection({
    super.key,
    required this.selectedOrgId,
    required this.orgs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DropdownButtonFormField<int?>(
      key: const Key('pet_org_selector'),
      value: selectedOrgId,
      decoration: InputDecoration(
        labelText: l.organizations,
        prefixIcon: const Icon(Icons.business),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: orgs
          .map((o) => DropdownMenuItem(
                value: o['id'] as int?,
                child: Text(o['name'] as String? ?? ''),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
