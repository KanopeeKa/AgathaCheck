import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../vet/domain/entities/vet.dart';
import '../../../../vet/presentation/providers/vet_providers.dart';
import '../../controllers/pet_form_controller.dart';

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
    final vetsAsync = ref.watch(vetListProvider);

    return vetsAsync.when(
      loading: () => InputDecorator(
        decoration: InputDecoration(labelText: l.veterinarians),
        child: const Text('Loading vets...'),
      ),
      error: (_, __) => InputDecorator(
        decoration: InputDecoration(labelText: l.veterinarians),
        child: const Text('Could not load vets'),
      ),
      data: (vets) {
        return DropdownButtonFormField<String?>(
          value: vets.any((v) => v.id == selectedVetId) ? selectedVetId : null,
          decoration: InputDecoration(
            labelText: l.veterinarians,
            suffixIcon: selectedVetId != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: 'Clear veterinarian',
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
                value: vet.id,
                child: Text(vet.name),
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
                    'Create new vet',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value == createNewVetSentinel) {
              showPetFormCreateVetSheet(
                context: context,
                ref: ref,
                onVetCreated: onVetSelected,
                controller: controller,
              );
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

Future<void> showPetFormCreateVetSheet({
  required BuildContext context,
  required WidgetRef ref,
  required ValueChanged<String?> onVetCreated,
  required PetFormController controller,
}) {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New Veterinarian',
              style: Theme.of(
                ctx,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('new_vet_name_field'),
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., Dr. Smith Veterinary Clinic',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('new_vet_phone_field'),
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('new_vet_email_field'),
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('new_vet_address_field'),
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address (optional)',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('save_new_vet_button'),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final vet = Vet(
                  id: '',
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  email: emailController.text.trim(),
                  address: addressController.text.trim(),
                );
                try {
                  await ref.read(vetListProvider.notifier).createVet(vet);
                  if (ctx.mounted) Navigator.pop(ctx);
                  final updatedVets = await ref.read(vetListProvider.future);
                  if (updatedVets.isNotEmpty) {
                    final newId = updatedVets.last.id;
                    onVetCreated(newId);
                    controller.state = controller.state.copyWith(
                      selectedVetId: newId,
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Failed to create vet: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    ),
  );
}
