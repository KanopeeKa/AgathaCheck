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

/// Guardian experience home (`/pc/home`).
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
      _redirectIfOnboardingNeeded();
      // Legacy PetListScreen called checkDueEntries on mount; guardian home must
      // prefetch notifications so the shell bell badge reflects API unread count.
      ref.read(notificationsProvider.notifier).checkDueEntries();
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
      experience: AppExperience.petCare,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: AppLocalizations.of(context)!.appTitle,
      child: petListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (pets) =>
            GuardianShellHomeContent(allPets: pets, controller: _controller),
      ),
    );
  }
}
