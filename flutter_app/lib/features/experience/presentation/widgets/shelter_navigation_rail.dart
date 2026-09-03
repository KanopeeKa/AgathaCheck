import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_experience.dart';
import '../config/shelter_primary_destinations.dart';
import 'experience_workspace_toggle.dart';

/// Leading navigation rail for Shelter workspace on medium widths (600–839px).
class ShelterNavigationRail extends ConsumerWidget {
  const ShelterNavigationRail({
    super.key,
    required this.currentLocation,
    this.pinnedOrg,
  });

  final String currentLocation;
  final ShelterPinnedOrganization? pinnedOrg;

  static const width = 120.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final destinations = ShelterPrimaryDestinations.navigableDestinations(
      pinnedOrg: pinnedOrg,
    );
    final selectedIndex = ShelterPrimaryDestinations.navigableIndexFor(
      currentLocation,
      pinnedOrg: pinnedOrg,
    );

    return Semantics(
      identifier: 'shelter_navigation_rail',
      container: true,
      child: SizedBox(
        key: const Key('shelter_navigation_rail'),
        width: width,
        child: NavigationRail(
          selectedIndex: selectedIndex,
          labelType: NavigationRailLabelType.all,
          backgroundColor: AppColorTokens.surface,
          indicatorColor: AppColorTokens.organizationPrimary.withValues(
            alpha: 0.16,
          ),
          selectedIconTheme: const IconThemeData(
            color: AppColorTokens.organizationPrimary,
            size: 24,
          ),
          unselectedIconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 24,
          ),
          selectedLabelTextStyle: const TextStyle(
            color: AppColorTokens.organizationPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
          minWidth: width,
          minExtendedWidth: width,
          useIndicator: true,
          leading: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  identifier: 'shelter_navigation_rail_brand',
                  label: l.appTitle,
                  child: AppLogoTitle(
                    title: l.appTitle,
                    experience: AppExperience.organization,
                    linkLogo: false,
                    showTitle: false,
                  ),
                ),
                const SizedBox(height: 8),
                ExperienceWorkspaceToggle(
                  currentLocation: currentLocation,
                  onDarkBackground: false,
                  showShelter: true,
                ),
              ],
            ),
          ),
          onDestinationSelected: (index) =>
              context.go(destinations[index].route),
          destinations: [
            for (final destination in destinations)
              NavigationRailDestination(
                icon: _RailDestinationSemantics(
                  destination: destination,
                  label: destination.labelBuilder(l),
                  icon: destination.icon,
                  pinnedOrg: destination.pinnedOrg,
                ),
                selectedIcon: _RailDestinationSemantics(
                  destination: destination,
                  label: destination.labelBuilder(l),
                  icon: destination.selectedIcon,
                  pinnedOrg: destination.pinnedOrg,
                  selected: true,
                ),
                label: Text(
                  destination.labelBuilder(l),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Semantics + touch target for each rail destination (E2E + a11y).
class _RailDestinationSemantics extends StatelessWidget {
  const _RailDestinationSemantics({
    required this.destination,
    required this.label,
    required this.icon,
    this.pinnedOrg,
    this.selected = false,
  });

  final ShelterPrimaryDestination destination;
  final String label;
  final IconData icon;
  final ShelterPinnedOrganization? pinnedOrg;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: ShelterPrimaryDestinations.semanticsIdentifier(
        destination.route,
      ),
      button: true,
      label: label,
      child: _RailDestinationIcon(
        icon: icon,
        pinnedOrg: pinnedOrg,
        selected: selected,
      ),
    );
  }
}

/// Ensures each rail destination meets the 48×48 logical px touch target.
class _RailDestinationIcon extends StatelessWidget {
  const _RailDestinationIcon({
    required this.icon,
    this.pinnedOrg,
    this.selected = false,
  });

  final IconData icon;
  final ShelterPinnedOrganization? pinnedOrg;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final child = pinnedOrg != null && pinnedOrg!.logoUrl.isNotEmpty
        ? CircleAvatar(
            radius: 14,
            backgroundColor: AppColorTokens.organizationSoft,
            backgroundImage: NetworkImage(pinnedOrg!.logoUrl),
          )
        : Icon(
            icon,
            color: selected
                ? AppColorTokens.organizationPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          );

    return SizedBox(width: 48, height: 48, child: Center(child: child));
  }
}
