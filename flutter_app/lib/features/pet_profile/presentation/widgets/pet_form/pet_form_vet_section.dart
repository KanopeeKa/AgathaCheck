import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../people/domain/entities/people_contact.dart';
import '../../controllers/pet_form_controller.dart';
import '../../providers/pet_vet_contacts_provider.dart';

const createNewVetSentinel = '__create_new_vet__';

class PetFormVetSection extends ConsumerWidget {
  const PetFormVetSection({
    super.key,
    required this.selectedVetId,
    required this.controller,
    required this.onVetSelected,
  });

  final String? selectedVetId;
  final PetFormController controller;
  final ValueChanged<String?> onVetSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final vetsAsync = ref.watch(petVetOptionsProvider);

    return vetsAsync.when(
      loading: () => InputDecorator(
        decoration: InputDecoration(labelText: l.veterinarians),
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => InputDecorator(
        decoration: InputDecoration(labelText: l.veterinarians),
        child: Text(l.peopleListLoadError),
      ),
      data: (vets) {
        return DropdownButtonFormField<String?>(
          isExpanded: true,
          initialValue: vets.any((v) => v.vetId == selectedVetId)
              ? selectedVetId
              : null,
          decoration: InputDecoration(
            labelText: l.veterinarians,
            suffixIcon: selectedVetId != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: l.clear,
                    onPressed: () {
                      onVetSelected(null);
                      controller.state = controller.state.copyWith(
                        selectedVetId: null,
                      );
                    },
                  )
                : null,
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(l.noVetAssigned),
            ),
            ...vets.map(
              (vet) => DropdownMenuItem<String?>(
                value: vet.vetId,
                child: Text(vet.displayName),
              ),
            ),
            DropdownMenuItem<String?>(
              value: createNewVetSentinel,
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.addNewVet,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (value) async {
            if (value == createNewVetSentinel) {
              final created = await context.push<PeopleContact?>(
                '/pc/people/new?roles=vet&pop=1',
              );
              final vetId = created?.legacyVetId;
              if (vetId != null && vetId.isNotEmpty) {
                onVetSelected(vetId);
                controller.state = controller.state.copyWith(
                  selectedVetId: vetId,
                );
              }
            } else {
              onVetSelected(value);
              controller.state = controller.state.copyWith(
                selectedVetId: value,
              );
            }
          },
        );
      },
    );
  }
}
