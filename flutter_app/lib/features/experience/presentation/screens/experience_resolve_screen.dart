import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../organization/presentation/providers/organization_providers.dart';
import '../../domain/services/experience_eligibility.dart';
import '../../domain/entities/app_experience.dart';

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
    final orgs = ref.read(organizationListProvider).valueOrNull ?? [];
    
    // Deterministic Landing Rules:
    // Has >0 pets -> Land on My Pets (/g/home)
    // Has 0 pets AND >0 shelters -> Land on Shelters (/o/home)
    // Has 0 pets AND 0 shelters -> Land on My Pets (/g/home)
    
    String path = '/g/home';
    if (pets.isNotEmpty) {
      path = '/g/home';
    } else if (pets.isEmpty && orgs.isNotEmpty) {
      path = '/o/home';
    } else {
      path = '/g/home';
    }
    
    // Set the active experience based on the path
    
    if (path.startsWith('/o/')) {
      ref.read(activeExperienceProvider.notifier).state = AppExperience.organization;
    } else {
      ref.read(activeExperienceProvider.notifier).state = AppExperience.guardian;
    }

    context.go(path);
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(organisationMembershipVisibilitySyncProvider);
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
