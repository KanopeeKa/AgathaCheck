import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../domain/entities/app_experience.dart';
import '../../domain/services/guardian_onboarding_rules.dart';
import '../providers/experience_providers.dart';
import '../widgets/experience_shell_scaffold.dart';
import '../widgets/guardian_shell_home_content.dart';
import '../widgets/org_shell_home_content.dart';

/// Guardian experience home (`/g/home`).
class GuardianHomeScreen extends ConsumerStatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  ConsumerState<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends ConsumerState<GuardianHomeScreen> {
  final _controller = PetListController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectIfOnboardingNeeded());
  }

  void _redirectIfOnboardingNeeded() {
    if (!mounted) return;
    final pets = ref.read(petListProvider).valueOrNull;
    if (pets == null) return;
    final completed = ref.read(guardianOnboardingCompletedProvider);
    if (GuardianOnboardingRules.needsOnboarding(
      pets: pets,
      onboardingCompleted: completed,
    )) {
      context.go(GuardianOnboardingRules.onboardingPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final petListAsync = ref.watch(petListProvider);
    final l = AppLocalizations.of(context);

    ref.listen(petListProvider, (_, next) {
      next.whenData((_) => _redirectIfOnboardingNeeded());
    });

    return ExperienceShellScaffold(
      experience: AppExperience.guardian,
      currentLocation: GoRouterState.of(context).uri.path,
      child: petListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (pets) => Stack(
          children: [
            GuardianShellHomeContent(allPets: pets, controller: _controller),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                key: const Key('add_pet_button'),
                onPressed: () => context.push('/add'),
                icon: const Icon(Icons.add),
                label: Text(l?.addPet ?? 'Add Pet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Organisation experience home (`/o/home`).
class OrgHomeScreen extends ConsumerStatefulWidget {
  const OrgHomeScreen({super.key});

  @override
  ConsumerState<OrgHomeScreen> createState() => _OrgHomeScreenState();
}

class _OrgHomeScreenState extends ConsumerState<OrgHomeScreen> {
  final _controller = PetListController();

  @override
  Widget build(BuildContext context) {
    final petListAsync = ref.watch(petListProvider);

    return ExperienceShellScaffold(
      experience: AppExperience.organization,
      currentLocation: GoRouterState.of(context).uri.path,
      child: petListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (pets) =>
            OrgShellHomeContent(allPets: pets, controller: _controller),
      ),
    );
  }
}
