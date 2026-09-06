import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Shared Guardian primary navigation destinations for compact bottom bar,
/// medium navigation rail, and expanded sidebar (phase 3).
class PetCarePrimaryDestination {
  const PetCarePrimaryDestination({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.labelBuilder,
  });

  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations l) labelBuilder;
}

/// Route detection, breakpoints, and destination metadata for Guardian shell nav.
class PetCarePrimaryDestinations {
  const PetCarePrimaryDestinations._();

  static const compactBreakpoint = 600.0;
  static const expandedBreakpoint = 840.0;

  static const routes = [
    '/pc/home',
    '/pc/pets',
    '/pc/events',
    '/pc/fostering',
    '/account',
  ];

  static bool isCompact(double width) => width < compactBreakpoint;

  static bool isMedium(double width) =>
      width >= compactBreakpoint && width < expandedBreakpoint;

  static bool isExpanded(double width) => width >= expandedBreakpoint;

  /// Whether [path] belongs to the Guardian (My Pets) workspace.
  static bool supports(String path) {
    if (path.startsWith('/o/')) return false;
    if (path == '/pc/onboarding' || path.startsWith('/pc/onboarding/')) {
      return false;
    }
    return path.startsWith('/pc/') ||
        path.startsWith('/pet/') ||
        path == '/add' ||
        path.startsWith('/edit/') ||
        path == '/account' ||
        path.startsWith('/account/') ||
        path.startsWith('/health');
  }

  static int indexFor(String path) {
    if (path == '/account' || path.startsWith('/account/')) return 4;
    if (path == '/pc/fostering' || path.startsWith('/pc/fostering/')) return 3;
    if (_isCarePath(path)) return 2;
    if (_isPetsPath(path)) return 1;
    return 0;
  }

  static bool _isCarePath(String path) {
    if (path == '/pc/events' || path.startsWith('/pc/events/')) return true;
    if (path.startsWith('/health')) return true;
    return RegExp(r'^/pet/[^/]+/(events|health|other)(?:/|$)').hasMatch(path);
  }

  static bool _isPetsPath(String path) {
    if (path == '/pc/pets' || path.startsWith('/pc/pets/')) return true;
    if (path == '/add' || path.startsWith('/add')) return true;
    if (RegExp(r'^/edit/').hasMatch(path)) return true;
    return path.startsWith('/pet/');
  }

  static List<PetCarePrimaryDestination> destinations() => const [
    PetCarePrimaryDestination(
      route: '/pc/home',
      icon: Icons.today_outlined,
      selectedIcon: Icons.today,
      labelBuilder: _dashboardLabel,
    ),
    PetCarePrimaryDestination(
      route: '/pc/pets',
      icon: Icons.pets_outlined,
      selectedIcon: Icons.pets,
      labelBuilder: _petsLabel,
    ),
    PetCarePrimaryDestination(
      route: '/pc/events',
      icon: Icons.favorite_border,
      selectedIcon: Icons.favorite,
      labelBuilder: _careLabel,
    ),
    PetCarePrimaryDestination(
      route: '/pc/fostering',
      icon: Icons.home_work_outlined,
      selectedIcon: Icons.home_work,
      labelBuilder: _fosteringLabel,
    ),
    PetCarePrimaryDestination(
      route: '/account',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      labelBuilder: _accountLabel,
    ),
  ];

  static String _dashboardLabel(AppLocalizations l) => l.dashboardNavLabel;
  static String _petsLabel(AppLocalizations l) => l.petsNavLabel;
  static String _careLabel(AppLocalizations l) => l.careNavLabel;
  static String _fosteringLabel(AppLocalizations l) => l.fostering;
  static String _accountLabel(AppLocalizations l) => l.accountTitle;

  /// Stable semantics identifier for E2E (`flt-semantics-identifier` on web).
  static String semanticsIdentifier(String route) {
    switch (route) {
      case '/pc/home':
        return 'pet_care_nav_dashboard';
      case '/pc/pets':
        return 'pet_care_nav_pets';
      case '/pc/events':
        return 'pet_care_nav_care';
      case '/pc/fostering':
        return 'pet_care_nav_fostering';
      case '/account':
        return 'pet_care_nav_account';
      default:
        return 'pet_care_nav_unknown';
    }
  }
}
