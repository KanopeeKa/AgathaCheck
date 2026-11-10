import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/invite_return.dart';
import '../../../../core/widgets/invite_recipient_block.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/services/experience_eligibility.dart';
import '../../../pet_profile/pet_profile.dart';
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

  void _resetNavigation() {
    _navigated = false;
  }

  void _navigate(ExperienceEligibility eligibility) {
    if (_navigated || !mounted) return;
    _navigated = true;

    final pets = ref.read(petListProvider).valueOrNull ?? [];
    final petCareOnboardingCompleted = ref.read(
      petCareOnboardingCompletedProvider,
    );
    final returnTo = inviteReturnToFromState(GoRouterState.of(context));
    var path = resolvePostLoginPath(
      eligibility: eligibility,
      pets: pets,
      petCareOnboardingCompleted: petCareOnboardingCompleted,
    );

    if (returnTo != null) {
      if (path == '/pc/onboarding') {
        path = appendInviteReturnQuery(path, returnTo);
      } else {
        path = returnTo;
      }
    }

    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    ref.listen<AsyncValue<ExperienceEligibility>>(
      experienceEligibilityProvider,
      (_, next) {
        next.whenData(_navigate);
      },
    );

    final eligibility = ref.watch(experienceEligibilityProvider);
    return eligibility.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) {
        return Scaffold(
          body: AsyncErrorState(
            title: l10n.entryResolutionFailed,
            onRetry: () {
              _resetNavigation();
              ref.invalidate(petListProvider);
            },
            retryKey: const Key('experience_resolve_retry'),
          ),
        );
      },
      data: (data) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _navigate(data);
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
