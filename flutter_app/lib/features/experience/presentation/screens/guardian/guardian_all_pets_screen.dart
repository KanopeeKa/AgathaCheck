import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/presentation/screens/pet_list_screen.dart';
import '../../widgets/experience_shell_scaffold.dart';
import '../../../domain/entities/app_experience.dart';

/// Full guardian pet list (`/g/pets`) — All Pets screen from the dashboard link.
class GuardianAllPetsScreen extends ConsumerWidget {
  const GuardianAllPetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return ExperienceShellScaffold(
      experience: AppExperience.guardian,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.allPets,
      child: const PetListScreen(embeddedInShell: true, enableBulkShare: true),
    );
  }
}
