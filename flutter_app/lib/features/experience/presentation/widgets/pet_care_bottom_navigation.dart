import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../config/pet_care_primary_destinations.dart';

/// Primary Guardian destinations on compact and touch-first screens.
///
/// Shelter switching stays in the shared drawer; this bar only exposes the
/// Guardian work a person performs most often.
class PetCareBottomNavigation extends StatelessWidget {
  const PetCareBottomNavigation({super.key, required this.currentLocation});

  final String currentLocation;

  static const compactBreakpoint = PetCarePrimaryDestinations.compactBreakpoint;

  /// Icon size for compact bottom bar (labels hidden; icons carry the affordance).
  static const bottomNavIconSize = 28.0;

  static bool isCompact(double width) =>
      PetCarePrimaryDestinations.isCompact(width);

  static bool supports(String path) =>
      PetCarePrimaryDestinations.supports(path);

  static int indexFor(String path) => PetCarePrimaryDestinations.indexFor(path);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final destinations = PetCarePrimaryDestinations.destinations();
    return SafeArea(
      top: false,
      child: BottomNavigationBar(
        key: const Key('pet_care_bottom_navigation'),
        type: BottomNavigationBarType.fixed,
        currentIndex: PetCarePrimaryDestinations.indexFor(currentLocation),
        backgroundColor: AppColorTokens.petCarePrimary,
        selectedItemColor: AppColorTokens.inverse,
        unselectedItemColor: AppColorTokens.petCareLight,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) => context.go(PetCarePrimaryDestinations.routes[index]),
        items: [
          for (final destination in destinations)
            BottomNavigationBarItem(
              icon: _BottomNavDestinationIcon(
                destination: destination,
                label: destination.labelBuilder(l),
                selected: false,
              ),
              activeIcon: _BottomNavDestinationIcon(
                destination: destination,
                label: destination.labelBuilder(l),
                selected: true,
              ),
              label: destination.labelBuilder(l),
            ),
        ],
      ),
    );
  }
}

/// Semantics + touch target for each bottom bar destination (E2E + a11y).
class _BottomNavDestinationIcon extends StatelessWidget {
  const _BottomNavDestinationIcon({
    required this.destination,
    required this.label,
    required this.selected,
  });

  final PetCarePrimaryDestination destination;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final icon = selected ? destination.selectedIcon : destination.icon;
    return Semantics(
      identifier: PetCarePrimaryDestinations.semanticsIdentifier(
        destination.route,
      ),
      button: true,
      label: label,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Icon(icon, size: PetCareBottomNavigation.bottomNavIconSize),
        ),
      ),
    );
  }
}
