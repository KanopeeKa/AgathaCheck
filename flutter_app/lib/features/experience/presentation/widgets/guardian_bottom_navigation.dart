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

  static bool supports(String path) => _destinations.any(
    (destination) => path == destination || path.startsWith('$destination/'),
  );

  static int indexFor(String path) {
    if (path == '/g/pets' || path.startsWith('/g/pets/')) return 1;
    if (path == '/g/events' || path.startsWith('/g/events/')) return 2;
    if (path == '/g/fostering' || path.startsWith('/g/fostering/')) return 3;
    if (path == '/account' || path.startsWith('/account/')) return 4;
    return 0;
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
