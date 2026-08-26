import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';

/// Primary Guardian destinations on compact and touch-first screens.
///
/// Shelter switching stays in the shared drawer; this bar only exposes the
/// Guardian work a person performs most often.
class GuardianBottomNavigation extends StatelessWidget {
  const GuardianBottomNavigation({super.key, required this.currentLocation});

  final String currentLocation;

  static const _destinations = [
    '/g/home',
    '/g/pets',
    '/g/events',
    '/g/fostering',
    '/account',
  ];
  static const compactBreakpoint = 600.0;

  static bool isCompact(double width) => width < compactBreakpoint;

  /// Whether [path] belongs to the Guardian (My Pets) workspace.
  static bool supports(String path) {
    if (path.startsWith('/o/')) return false;
    if (path == '/g/onboarding' || path.startsWith('/g/onboarding/')) {
      return false;
    }
    return path.startsWith('/g/') ||
        path.startsWith('/pet/') ||
        path == '/add' ||
        path.startsWith('/edit/') ||
        path == '/account' ||
        path.startsWith('/account/') ||
        path.startsWith('/health');
  }

  static int indexFor(String path) {
    if (path == '/account' || path.startsWith('/account/')) return 4;
    if (path == '/g/fostering' || path.startsWith('/g/fostering/')) return 3;
    if (_isCarePath(path)) return 2;
    if (_isPetsPath(path)) return 1;
    return 0;
  }

  static bool _isCarePath(String path) {
    if (path == '/g/events' || path.startsWith('/g/events/')) return true;
    if (path.startsWith('/health')) return true;
    return RegExp(r'^/pet/[^/]+/(events|health|other)(?:/|$)').hasMatch(path);
  }

  static bool _isPetsPath(String path) {
    if (path == '/g/pets' || path.startsWith('/g/pets/')) return true;
    if (path == '/add' || path.startsWith('/add')) return true;
    if (RegExp(r'^/edit/').hasMatch(path)) return true;
    return path.startsWith('/pet/');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: BottomNavigationBar(
        key: const Key('guardian_bottom_navigation'),
        type: BottomNavigationBarType.fixed,
        currentIndex: indexFor(currentLocation),
        backgroundColor: AppColorTokens.guardianPrimary,
        selectedItemColor: AppColorTokens.inverse,
        unselectedItemColor: AppColorTokens.guardianLight,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        onTap: (index) => context.go(_destinations[index]),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.today_outlined),
            activeIcon: const Icon(Icons.today),
            label: l.today,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.pets_outlined),
            activeIcon: const Icon(Icons.pets),
            label: l.petsNavLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_border),
            activeIcon: const Icon(Icons.favorite),
            label: l.careNavLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_work_outlined),
            activeIcon: const Icon(Icons.home_work),
            label: l.fostering,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: l.accountTitle,
          ),
        ],
      ),
    );
  }
}
