import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/pet.dart';
import '../../controllers/pet_profile_controller.dart';

class PetProfileCard extends ConsumerWidget {
  const PetProfileCard({required this.pet, super.key});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = PetProfileController(ref);
    final assignedVet = controller.getAssignedVet(pet);
    final displayWeight = controller.getDisplayWeight(pet);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 140,
                child: _PetPhoto(pet: pet),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(pet.name,
                                style: theme.textTheme.headlineSmall),
                          ),
                          if (assignedVet != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Tooltip(
                                message: assignedVet.name,
                                child: const Icon(Icons.local_hospital, size: 20),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Weight: ${displayWeight?.toStringAsFixed(1) ?? '-'} kg',
                          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
                      // ... add more fields as needed ...
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// TODO: Extract _PetPhoto as a separate widget if needed, or import if already extracted.
class _PetPhoto extends StatelessWidget {
  const _PetPhoto({required this.pet});
  final Pet pet;
  @override
  Widget build(BuildContext context) {
    // Placeholder for pet photo logic
    return Container(color: Colors.grey[300], child: const Icon(Icons.pets, size: 64));
  }
}
