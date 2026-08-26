import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../config/guardian_primary_destinations.dart';

/// Primary Guardian destinations on compact and touch-first screens.
///
/// Shelter switching stays in the shared drawer; this bar only exposes the
/// Guardian work a person performs most often.
class GuardianBottomNavigation extends StatelessWidget {
  const GuardianBottomNavigation({super.key, required this.currentLocation});

  final String currentLocation;

  static const compactBreakpoint =
      GuardianPrimaryDestinations.compactBreakpoint;

  static bool isCompact(double width) =>
      GuardianPrimaryDestinations.isCompact(width);

  static bool supports(String path) =>
      GuardianPrimaryDestinations.supports(path);

  static int indexFor(String path) =>
      GuardianPrimaryDestinations.indexFor(path);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final destinations = GuardianPrimaryDestinations.destinations();
    return SafeArea(
      top: false,
      child: BottomNavigationBar(
        key: const Key('guardian_bottom_navigation'),
        type: BottomNavigationBarType.fixed,
        currentIndex: GuardianPrimaryDestinations.indexFor(currentLocation),
        backgroundColor: AppColorTokens.guardianPrimary,
        selectedItemColor: AppColorTokens.inverse,
        unselectedItemColor: AppColorTokens.guardianLight,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        onTap: (index) => context.go(GuardianPrimaryDestinations.routes[index]),
        items: [
          for (final destination in destinations)
            BottomNavigationBarItem(
              icon: Icon(destination.icon),
              activeIcon: Icon(destination.selectedIcon),
              label: destination.labelBuilder(l),
            ),
        ],
      ),
    );
  }
}
