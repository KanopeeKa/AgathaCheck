import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../domain/entities/app_experience.dart';
import '../../../organization/presentation/providers/organization_providers.dart';
import '../../domain/services/guardian_onboarding_rules.dart';
import '../../domain/services/org_onboarding_rules.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).refresh();
      _redirectIfOnboardingNeeded();
    });
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

    ref.listen(petListProvider, (_, next) {
      next.whenData((_) => _redirectIfOnboardingNeeded());
    });

    return ExperienceShellScaffold(
      experience: AppExperience.guardian,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: AppLocalizations.of(context)!.guardianDashboardTitle,
      child: petListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (pets) =>
            GuardianShellHomeContent(allPets: pets, controller: _controller),
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _redirectIfOnboardingNeeded(),
    );
  }

  void _redirectIfOnboardingNeeded() {
    if (!mounted) return;
    final pets = ref.read(petListProvider).valueOrNull;
    final orgs = ref.read(organizationListProvider).valueOrNull;
    if (pets == null || orgs == null) return;
    final completed = ref.read(orgOnboardingCompletedProvider);
    if (OrgOnboardingRules.needsOnboarding(
      pets: pets,
      orgs: orgs,
      onboardingCompleted: completed,
    )) {
      context.go(OrgOnboardingRules.onboardingPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final petListAsync = ref.watch(petListProvider);

    ref.listen(petListProvider, (_, next) {
      next.whenData((_) => _redirectIfOnboardingNeeded());
    });
    ref.listen(organizationListProvider, (_, next) {
      next.whenData((_) => _redirectIfOnboardingNeeded());
    });

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
