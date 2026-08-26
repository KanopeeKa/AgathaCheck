import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';

/// Bottom sheet: Events / Weight entry — routes to existing entry forms.
Future<void> showAddEventTypePickerSheet(
  BuildContext context, {
  required List<Pet> pets,
}) {
  final l = AppLocalizations.of(context)!;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l.addAnEvent,
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.medical_services_outlined),
              title: Text(l.addEventEventsOption),
              subtitle: Text(l.addHealthEntry),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/health/add');
              },
            ),
            ListTile(
              leading: const Icon(Icons.monitor_weight_outlined),
              title: Text(l.addEventWeightEntryOption),
              subtitle: Text(l.addWeightEntry),
              onTap: () {
                Navigator.pop(ctx);
                _pickPetForWeight(context, pets);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

void _pickPetForWeight(BuildContext context, List<Pet> pets) {
  final active = pets.where((p) => !p.passedAway).toList();
  if (active.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.noPetsYet)),
    );
    return;
  }
  if (active.length == 1) {
    context.go('/pet/${active.first.id}');
    return;
  }
  _showPetPickerSheet(
    context,
    pets: active,
    title: AppLocalizations.of(context)!.selectPetForWeight,
  );
}

Future<void> _showPetPickerSheet(
  BuildContext context, {
  required List<Pet> pets,
  required String title,
  void Function(Pet pet)? onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                title,
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...pets.map(
              (pet) => ListTile(
                title: Text(pet.name),
                onTap: () {
                  Navigator.pop(ctx);
                  if (onSelected != null) {
                    onSelected(pet);
                  } else {
                    context.go('/pet/${pet.id}');
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
