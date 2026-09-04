import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Minimal pinned-org payload for Shelter primary nav (phase 2).
///
/// Provider wiring lands in later phases; tests pass this directly.
class ShelterPinnedOrganization {
  const ShelterPinnedOrganization({
    required this.id,
    required this.name,
    this.logoUrl = '',
  });

  final String id;
  final String name;
  final String logoUrl;
}

/// One slot in the five-position Shelter bottom bar (D-shelter-NAV-3).
enum ShelterNavSlotKind { destination, spacer, hidden }

/// Shared Shelter primary navigation destination metadata.
class ShelterPrimaryDestination {
  const ShelterPrimaryDestination({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.labelBuilder,
    this.pinnedOrg,
  });

  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations l) labelBuilder;

  /// When set, compact nav may show the org logo instead of [icon].
  final ShelterPinnedOrganization? pinnedOrg;
}

/// One visual position in the Shelter bottom bar.
class ShelterNavSlot {
  const ShelterNavSlot._({required this.kind, this.destination});

  const ShelterNavSlot.destination(ShelterPrimaryDestination destination)
    : this._(kind: ShelterNavSlotKind.destination, destination: destination);

  const ShelterNavSlot.spacer() : this._(kind: ShelterNavSlotKind.spacer);

  const ShelterNavSlot.hidden() : this._(kind: ShelterNavSlotKind.hidden);

  final ShelterNavSlotKind kind;
  final ShelterPrimaryDestination? destination;

  String? get route => destination?.route;
}

/// Route detection, breakpoints, and destination metadata for Shelter shell nav.
class ShelterPrimaryDestinations {
  const ShelterPrimaryDestinations._();

  static const compactBreakpoint = 600.0;
  static const expandedBreakpoint = 840.0;

  static const dashboardRoute = '/o/orgs';
  static const discoverRoute = '/o/orgs/discover';
  static const accountRoute = '/account';

  static bool isCompact(double width) => width < compactBreakpoint;

  static bool isMedium(double width) =>
      width >= compactBreakpoint && width < expandedBreakpoint;

  static bool isExpanded(double width) => width >= expandedBreakpoint;

  /// Whether [path] belongs to the Shelter workspace primary nav shell.
  static bool supports(String path) {
    if (path == '/o/onboarding' || path.startsWith('/o/onboarding/')) {
      return false;
    }
    return path.startsWith('/o/') ||
        path == accountRoute ||
        path.startsWith('/account/');
  }

  /// Selected bottom-bar slot (0–4) for [path].
  static int indexFor(String path, {ShelterPinnedOrganization? pinnedOrg}) {
    if (path == accountRoute || path.startsWith('/account/')) return 4;
    if (_isDiscoverPath(path)) return 3;
    if (pinnedOrg != null && _isPinnedOrgPath(path, pinnedOrg.id)) return 1;
    if (path.startsWith('/o/')) return 0;
    return 0;
  }

  /// Tappable destinations for rail and sidebar (no spacer/hidden slots).
  static List<ShelterPrimaryDestination> navigableDestinations({
    ShelterPinnedOrganization? pinnedOrg,
  }) {
    return [
      _dashboardDestination(),
      if (pinnedOrg != null) _pinnedDestination(pinnedOrg),
      _discoverDestination(),
      _accountDestination(),
    ];
  }

  /// Selected index within [navigableDestinations] for [path].
  static int navigableIndexFor(
    String path, {
    ShelterPinnedOrganization? pinnedOrg,
  }) {
    final destinations = navigableDestinations(pinnedOrg: pinnedOrg);
    final slotIndex = indexFor(path, pinnedOrg: pinnedOrg);
    if (slotIndex == 4) return destinations.length - 1;
    if (slotIndex == 3) return pinnedOrg != null ? 2 : 1;
    if (slotIndex == 1) return 1;
    return 0;
  }

  /// Full five-slot bottom bar geometry (D-shelter-NAV-3).
  static List<ShelterNavSlot> slots({ShelterPinnedOrganization? pinnedOrg}) {
    final hasPin = pinnedOrg != null;
    return [
      ShelterNavSlot.destination(_dashboardDestination()),
      hasPin
          ? ShelterNavSlot.destination(_pinnedDestination(pinnedOrg))
          : const ShelterNavSlot.hidden(),
      hasPin ? const ShelterNavSlot.hidden() : const ShelterNavSlot.spacer(),
      ShelterNavSlot.destination(_discoverDestination()),
      ShelterNavSlot.destination(_accountDestination()),
    ];
  }

  static String? routeAt(
    int slotIndex, {
    ShelterPinnedOrganization? pinnedOrg,
  }) {
    final slot = slots(pinnedOrg: pinnedOrg)[slotIndex];
    return slot.route;
  }

  static ShelterPrimaryDestination _dashboardDestination() {
    return const ShelterPrimaryDestination(
      route: dashboardRoute,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      labelBuilder: _dashboardLabel,
    );
  }

  static ShelterPrimaryDestination _discoverDestination() {
    return const ShelterPrimaryDestination(
      route: discoverRoute,
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      labelBuilder: _discoverLabel,
    );
  }

  static ShelterPrimaryDestination _accountDestination() {
    return const ShelterPrimaryDestination(
      route: accountRoute,
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      labelBuilder: _accountLabel,
    );
  }

  static ShelterPrimaryDestination _pinnedDestination(
    ShelterPinnedOrganization pinnedOrg,
  ) {
    return ShelterPrimaryDestination(
      route: '/o/orgs/${pinnedOrg.id}',
      icon: Icons.home_work_outlined,
      selectedIcon: Icons.home_work,
      labelBuilder: (_) => pinnedOrg.name,
      pinnedOrg: pinnedOrg,
    );
  }

  static bool _isDiscoverPath(String path) {
    return path == discoverRoute || path.startsWith('$discoverRoute?');
  }

  static bool _isPinnedOrgPath(String path, String orgId) {
    if (path == '/o/orgs/$orgId') return true;
    return path.startsWith('/o/orgs/$orgId/');
  }

  static String _dashboardLabel(AppLocalizations l) => l.dashboardNavLabel;
  static String _discoverLabel(AppLocalizations l) => l.discoverOrganizations;
  static String _accountLabel(AppLocalizations l) => l.accountTitle;

  /// Stable semantics identifier for E2E (`flt-semantics-identifier` on web).
  static String semanticsIdentifier(String route) {
    switch (route) {
      case dashboardRoute:
        return 'shelter_nav_dashboard';
      case discoverRoute:
        return 'shelter_nav_discover';
      case accountRoute:
        return 'shelter_nav_account';
      default:
        if (route.startsWith('/o/orgs/') &&
            route != discoverRoute &&
            !route.startsWith('$discoverRoute?')) {
          return 'shelter_nav_pinned_org';
        }
        return 'shelter_nav_unknown';
    }
  }
}
