import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../organization/presentation/providers/organization_providers.dart';
import '../../domain/services/experience_eligibility.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../providers/experience_providers.dart';

/// Loads eligibility after login and routes to FTUE or the correct home.
class ExperienceResolveScreen extends ConsumerWidget {
  const ExperienceResolveScreen({super.key});

  void _navigate(
    BuildContext context,
    WidgetRef ref,
    ExperienceEligibility eligibility, {
    required bool hasPendingOrgInvites,
  }) {
    final pets = ref.read(petListProvider).valueOrNull ?? [];
    final orgs = ref.read(organizationListProvider).valueOrNull ?? [];
    final guardianOnboardingCompleted = ref.read(
      guardianOnboardingCompletedProvider,
    );
    final orgOnboardingCompleted = ref.read(orgOnboardingCompletedProvider);
    final lastAppSection = ref
        .read(experiencePreferencesStoreProvider)
        .readLastAppSection();
    final path = resolvePostLoginPath(
      eligibility: eligibility,
      pets: pets,
      orgs: orgs,
      guardianOnboardingCompleted: guardianOnboardingCompleted,
      orgOnboardingCompleted: orgOnboardingCompleted,
      hasPendingOrgInvites: hasPendingOrgInvites,
      lastAppSection: lastAppSection,
    );
    context.go(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(organisationMembershipVisibilitySyncProvider);
    final pendingInvites = ref.watch(pendingOrgInvitesProvider);
    final hasPendingOrgInvites = pendingInvites.maybeWhen(
      data: (invites) => invites.isNotEmpty,
      orElse: () => false,
    );

    ref.listen<AsyncValue<ExperienceEligibility>>(
      experienceEligibilityProvider,
      (_, next) {
        next.whenData(
          (eligibility) => _navigate(
            context,
            ref,
            eligibility,
            hasPendingOrgInvites: hasPendingOrgInvites,
          ),
        );
      },
    );

    final eligibility = ref.watch(experienceEligibilityProvider);
    eligibility.whenOrNull(
      data: (e) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          _navigate(
            context,
            ref,
            e,
            hasPendingOrgInvites: hasPendingOrgInvites,
          );
        });
      },
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/pc/home');
        });
      },
    );

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
