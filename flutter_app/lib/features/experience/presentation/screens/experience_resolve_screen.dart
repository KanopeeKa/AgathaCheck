import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/services/experience_eligibility.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../providers/experience_providers.dart';

/// Loads eligibility after login and routes to chooser or the correct home.
class ExperienceResolveScreen extends ConsumerWidget {
  const ExperienceResolveScreen({super.key});

  void _navigate(
    BuildContext context,
    WidgetRef ref,
    ExperienceEligibility eligibility,
  ) {
    final pets = ref.read(petListProvider).valueOrNull ?? [];
    final saved = ref.read(savedDefaultExperienceProvider);
    final active = ref.read(activeExperienceProvider);
    final onboardingCompleted = ref.read(guardianOnboardingCompletedProvider);
    final path = resolvePostLoginPath(
      eligibility: eligibility,
      savedDefault: saved,
      activeExperience: active,
      pets: pets,
      guardianOnboardingCompleted: onboardingCompleted,
    );
    context.go(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<ExperienceEligibility>>(
      experienceEligibilityProvider,
      (_, next) {
        next.whenData((eligibility) => _navigate(context, ref, eligibility));
      },
    );

    final eligibility = ref.watch(experienceEligibilityProvider);
    eligibility.whenOrNull(
      data: (e) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          _navigate(context, ref, e);
        });
      },
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/g/home');
        });
      },
    );

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
