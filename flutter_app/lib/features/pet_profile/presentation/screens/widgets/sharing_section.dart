import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/pet.dart';
import '../../../sharing/domain/entities/pet_access.dart';
import '../../controllers/sharing_controller.dart';
import '../../../organization/presentation/providers/organization_providers.dart';
import '../../../../l10n/app_localizations.dart';

class SharingSection extends ConsumerWidget {
  const SharingSection({required this.petId, required this.pet, super.key});

  final String petId;
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = SharingController(ref);
    final l = AppLocalizations.of(context)!;
    // ...rest of the sharing section UI, now call controller for logic...
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: Icon(Icons.people, color: Theme.of(context).colorScheme.primary),
          title: Text(l.sharingSection,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          children: [
            // ...rest of the sharing section UI, now call controller for logic...
          ],
        ),
      ),
    );
  }
}
