import 'package:flutter/material.dart';
import '../../../../../../l10n/app_localizations.dart';

class PetVetSection extends StatelessWidget {
  final String? selectedVetId;
  final List<Map<String, String>> vets;
  final ValueChanged<String?> onChanged;
  final VoidCallback onCreateVet;

  const PetVetSection({
    super.key,
    required this.selectedVetId,
    required this.vets,
    required this.onChanged,
    required this.onCreateVet,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String?>(
      key: const Key('pet_vet_field'),
      value: selectedVetId,
      decoration: InputDecoration(
        labelText: l.veterinarians,
        helperText: 'Assign a veterinarian',
        suffixIcon: selectedVetId != null
            ? IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear veterinarian',
                onPressed: () => onChanged(null),
              )
            : const Icon(Icons.info_outline),
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(l.noVetAssigned),
        ),
        ...vets.map((vet) => DropdownMenuItem<String?>(
              value: vet['id'],
              child: Text(vet['name'] ?? ''),
            )),
        DropdownMenuItem<String?>(
          value: '_createNewVet',
          child: Row(
            children: [
              const Icon(Icons.add_circle_outline, size: 18),
              SizedBox(width: 8),
              Text('Create new vet', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        if (value == '_createNewVet') {
          onCreateVet();
        } else {
          onChanged(value);
        }
      },
    );
  }
}
