import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/async_state/async_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../notifications/notifications.dart';
import '../../../pet_profile/pet_profile.dart';
import '../../domain/entities/app_experience.dart';
import '../../domain/services/pet_care_onboarding_rules.dart';
import '../providers/experience_providers.dart';
import '../widgets/experience_shell_scaffold.dart';
import '../widgets/pet_care_shell_home_content.dart';

/// Guardian experience home (`/pc/home`).
class PetCareHomeScreen extends ConsumerStatefulWidget {
  const PetCareHomeScreen({super.key});

  @override
  ConsumerState<PetCareHomeScreen> createState() => _PetCareHomeScreenState();
}

class _PetCareHomeScreenState extends ConsumerState<PetCareHomeScreen> {
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
    final completed = ref.read(petCareOnboardingCompletedProvider);
    if (PetCareOnboardingRules.needsOnboarding(
      pets: pets,
      onboardingCompleted: completed,
    )) {
      context.go(PetCareOnboardingRules.onboardingPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final petListAsync = ref.watch(petListProvider);

    ref.listen(petListProvider, (_, next) {
      next.whenData((_) => _redirectIfOnboardingNeeded());
    });

    final l = AppLocalizations.of(context)!;

    Widget petsBody(List<Pet> pets) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PetListStaleBanner(),
        Expanded(
          child: PetCareShellHomeContent(
            allPets: pets,
            controller: _controller,
          ),
        ),
      ],
    );

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.appTitle,
      child: petListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final cached = petListAsync.valueOrNull;
          if (cached != null) {
            return petsBody(cached);
          }
          return AsyncErrorState(
            title: l.loadErrorYourPets,
            onRetry: () => ref.invalidate(petListProvider),
            retryKey: const Key('home_pet_list_retry'),
          );
        },
        data: petsBody,
      ),
    );
  }
}
