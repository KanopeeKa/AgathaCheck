import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../organization/presentation/providers/organization_providers.dart';
import '../providers/experience_providers.dart';

/// Redirects foster-portal org members away from routes hidden in the drawer.
class FosterPortalRouteGuard extends ConsumerStatefulWidget {
  const FosterPortalRouteGuard({
    super.key,
    required this.fallbackPath,
    required this.child,
  });

  final String fallbackPath;
  final Widget child;

  @override
  ConsumerState<FosterPortalRouteGuard> createState() =>
      _FosterPortalRouteGuardState();
}

class _FosterPortalRouteGuardState
    extends ConsumerState<FosterPortalRouteGuard> {
  var _redirected = false;

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(organizationListProvider);
    final isFosterPortal = ref.watch(isFosterPortalUserProvider);

    if (orgsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Single redirect to [fallbackPath]; [_redirected] prevents loops if the guard rebuilds.
    if (isFosterPortal && !_redirected) {
      _redirected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(widget.fallbackPath);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return widget.child;
  }
}
