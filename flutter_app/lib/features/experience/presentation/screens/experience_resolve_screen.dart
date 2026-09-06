import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../organization/presentation/providers/organization_providers.dart';
import '../../domain/services/experience_eligibility.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../providers/experience_providers.dart';

/// Loads eligibility after login and routes to the Pet Care home (D-v5-WORKSPACE-2).
class ExperienceResolveScreen extends ConsumerStatefulWidget {
  const ExperienceResolveScreen({super.key});

  @override
  ConsumerState<ExperienceResolveScreen> createState() =>
      _ExperienceResolveScreenState();
}

class _ExperienceResolveScreenState
    extends ConsumerState<ExperienceResolveScreen> {
  bool _navigated = false;

  void _navigate(ExperienceEligibility eligibility) {
    if (_navigated || !mounted) return;
    _navigated = true;

    final pets = ref.read(petListProvider).valueOrNull ?? [];
    final orgs = ref.read(organizationListProvider).valueOrNull ?? [];
    final petCareOnboardingCompleted = ref.read(
      petCareOnboardingCompletedProvider,
    );
    final orgOnboardingCompleted = ref.read(orgOnboardingCompletedProvider);
    final hasPendingOrgInvites = ref
        .read(pendingOrgInvitesProvider)
        .maybeWhen(data: (invites) => invites.isNotEmpty, orElse: () => false);
    final path = resolvePostLoginPath(
      eligibility: eligibility,
      pets: pets,
      orgs: orgs,
      petCareOnboardingCompleted: petCareOnboardingCompleted,
      orgOnboardingCompleted: orgOnboardingCompleted,
      hasPendingOrgInvites: hasPendingOrgInvites,
    );
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ExperienceEligibility>>(
      experienceEligibilityProvider,
      (_, next) {
        next.whenData(_navigate);
      },
    );

    final eligibility = ref.watch(experienceEligibilityProvider);
    eligibility.whenOrNull(
      data: (data) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _navigate(data);
        });
      },
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_navigated || !mounted) return;
          _navigated = true;
          context.go('/pc/home');
        });
      },
    );

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
