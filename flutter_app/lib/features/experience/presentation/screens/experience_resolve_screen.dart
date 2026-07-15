import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/services/experience_eligibility.dart';
import '../providers/experience_providers.dart';

/// Loads eligibility after login and routes to chooser or the correct home.
class ExperienceResolveScreen extends ConsumerWidget {
  const ExperienceResolveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<ExperienceEligibility>>(
      experienceEligibilityProvider,
      (_, next) {
        next.whenData((eligibility) {
          final saved = ref.read(savedDefaultExperienceProvider);
          final active = ref.read(activeExperienceProvider);
          final path = resolvePostLoginPath(
            eligibility: eligibility,
            savedDefault: saved,
            activeExperience: active,
          );
          context.go(path);
        });
      },
    );

    final eligibility = ref.watch(experienceEligibilityProvider);
    eligibility.whenOrNull(
      data: (e) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          final saved = ref.read(savedDefaultExperienceProvider);
          final active = ref.read(activeExperienceProvider);
          context.go(
            resolvePostLoginPath(
              eligibility: e,
              savedDefault: saved,
              activeExperience: active,
            ),
          );
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
