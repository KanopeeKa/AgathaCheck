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
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        onTap: (index) => context.go(PetCarePrimaryDestinations.routes[index]),
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
