import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../organization/presentation/providers/organization_providers.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../domain/services/org_onboarding_rules.dart';
import '../providers/experience_providers.dart';

/// Redirects org super-admins to onboarding when entering the shelter workspace.
class OrgOnboardingRouteGuard extends ConsumerStatefulWidget {
  const OrgOnboardingRouteGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OrgOnboardingRouteGuard> createState() =>
      _OrgOnboardingRouteGuardState();
}

class _OrgOnboardingRouteGuardState
    extends ConsumerState<OrgOnboardingRouteGuard> {
  var _redirected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectIfOnboardingNeeded();
    });
  }

  void _redirectIfOnboardingNeeded() {
    if (!mounted || _redirected) return;
    final pets = ref.read(petListProvider).valueOrNull;
    final orgs = ref.read(organizationListProvider).valueOrNull;
    if (pets == null || orgs == null) return;
    final completed = ref.read(orgOnboardingCompletedProvider);
    if (!OrgOnboardingRules.needsOnboarding(
      pets: pets,
      orgs: orgs,
      onboardingCompleted: completed,
    )) {
      return;
    }
    _redirected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(OrgOnboardingRules.onboardingPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petListProvider);
    final orgsAsync = ref.watch(organizationListProvider);

    ref.listen(petListProvider, (_, next) {
      next.whenData((_) => _redirectIfOnboardingNeeded());
    });
    ref.listen(organizationListProvider, (_, next) {
      next.whenData((_) => _redirectIfOnboardingNeeded());
    });

    if (petsAsync.isLoading || orgsAsync.isLoading || _redirected) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return widget.child;
  }
}
