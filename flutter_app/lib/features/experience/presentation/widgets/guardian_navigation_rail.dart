import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../config/guardian_primary_destinations.dart';

/// Leading navigation rail for Guardian workspace on medium widths (600–839px).
class GuardianNavigationRail extends StatelessWidget {
  const GuardianNavigationRail({super.key, required this.currentLocation});

  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final destinations = GuardianPrimaryDestinations.destinations();
    final selectedIndex = GuardianPrimaryDestinations.indexFor(currentLocation);

    return NavigationRail(
      key: const Key('guardian_navigation_rail'),
      selectedIndex: selectedIndex,
      labelType: NavigationRailLabelType.all,
      backgroundColor: AppColorTokens.background,
      indicatorColor: AppColorTokens.guardianPrimary.withValues(alpha: 0.16),
      selectedIconTheme: const IconThemeData(
        color: AppColorTokens.guardianPrimary,
        size: 24,
      ),
      unselectedIconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 24,
      ),
      selectedLabelTextStyle: const TextStyle(
        color: AppColorTokens.guardianPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 12,
      ),
      minWidth: 72,
      minExtendedWidth: 72,
      useIndicator: true,
      onDestinationSelected: (index) =>
          context.go(GuardianPrimaryDestinations.routes[index]),
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: _RailDestinationIcon(icon: destination.icon),
            selectedIcon: _RailDestinationIcon(icon: destination.selectedIcon),
            label: Text(destination.labelBuilder(l)),
          ),
      ],
    );
  }
}

/// Ensures each rail destination meets the 48×48 logical px touch target.
class _RailDestinationIcon extends StatelessWidget {
  const _RailDestinationIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(child: Icon(icon)),
    );
  }
}
