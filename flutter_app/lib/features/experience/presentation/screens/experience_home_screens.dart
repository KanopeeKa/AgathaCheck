import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../organization/presentation/screens/organization_list_screen.dart';
import '../../../pet_profile/presentation/screens/pet_list_screen.dart';
import '../../domain/entities/app_experience.dart';
import '../widgets/experience_shell_scaffold.dart';

/// Guardian experience home (`/g/home`).
class GuardianHomeScreen extends ConsumerWidget {
  const GuardianHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExperienceShellScaffold(
      experience: AppExperience.guardian,
      currentLocation: GoRouterState.of(context).uri.path,
      child: const PetListScreen(embeddedInShell: true),
    );
  }
}

/// Organisation experience home (`/o/home`).
class OrgHomeScreen extends ConsumerWidget {
  const OrgHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExperienceShellScaffold(
      experience: AppExperience.organization,
      currentLocation: GoRouterState.of(context).uri.path,
      child: const OrganizationListScreen(embeddedInShell: true),
    );
  }
}
