import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/shell_return_navigation.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../../health_tracking/presentation/widgets/add_health_entry_navigation.dart';
import '../providers/pet_providers.dart';
import '../widgets/all_care/all_care_list.dart';

/// Pet-scoped All care destination — unified temporal list of care items.
class PetManageEventsScreen extends ConsumerWidget {
  const PetManageEventsScreen({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final petsAsync = ref.watch(allPetsIncludingOrgProvider);
    final experience = AppExperience.petCare;

    return petsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (pets) {
        final pet = pets.where((p) => p.id == petId).firstOrNull;
        if (pet == null) {
          return Scaffold(body: Center(child: Text(l.petNotFound)));
        }

        return ExperienceShellScaffold(
          experience: experience,
          currentLocation: GoRouterState.of(context).uri.path,
          screenTitle: l.allCareTitle(pet.name),
          backPath: petDetailBackPath(context, petId),
          contextualActions: [
            IconButton(
              key: const Key('manage_events_add_app_bar'),
              tooltip: l.addAnEvent,
              icon: const Icon(Icons.add),
              onPressed: () => navigateToAddHealthEntry(context, petId: petId),
            ),
          ],
          child: AllCareList(petId: petId),
        );
      },
    );
  }
}
