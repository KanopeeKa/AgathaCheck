import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_experience.dart';
import '../config/drawer_menu_config.dart';
import '../config/guardian_primary_destinations.dart';
import '../providers/experience_providers.dart';
import 'experience_workspace_toggle.dart';

/// Leading navigation rail for Guardian workspace on medium widths (600–839px).
class GuardianNavigationRail extends ConsumerWidget {
  const GuardianNavigationRail({super.key, required this.currentLocation});

  final String currentLocation;

  static const width = 120.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final destinations = GuardianPrimaryDestinations.destinations();
    final selectedIndex = GuardianPrimaryDestinations.indexFor(currentLocation);
    final isRoot = DrawerMenuConfig.sectionRootPaths.contains(currentLocation);
    final showShelterWorkspace =
        isRoot &&
        (currentLocation.startsWith('/o/') ||
            ref.watch(showOrganisationSectionProvider));

    return Semantics(
      identifier: 'guardian_navigation_rail',
      container: true,
      child: SizedBox(
        key: const Key('guardian_navigation_rail'),
        width: width,
        child: NavigationRail(
          selectedIndex: selectedIndex,
          labelType: NavigationRailLabelType.all,
          backgroundColor: AppColorTokens.background,
          indicatorColor: AppColorTokens.petCarePrimary.withValues(alpha: 0.16),
          selectedIconTheme: const IconThemeData(
            color: AppColorTokens.petCarePrimary,
            size: 24,
          ),
          unselectedIconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 24,
          ),
          selectedLabelTextStyle: const TextStyle(
            color: AppColorTokens.petCarePrimary,
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
                  identifier: 'guardian_navigation_rail_brand',
                  label: l.appTitle,
                  child: AppLogoTitle(
                    title: l.appTitle,
                    experience: AppExperience.petCare,
                    linkLogo: false,
                    showTitle: false,
                  ),
                ),
                if (isRoot) ...[
                  const SizedBox(height: 8),
                  ExperienceWorkspaceToggle(
                    currentLocation: currentLocation,
                    onDarkBackground: false,
                    showShelter: showShelterWorkspace,
                  ),
                ],
              ],
            ),
          ),
          onDestinationSelected: (index) =>
              context.go(GuardianPrimaryDestinations.routes[index]),
          destinations: [
            for (final destination in destinations)
              NavigationRailDestination(
                icon: _RailDestinationSemantics(
                  destination: destination,
                  label: destination.labelBuilder(l),
                  icon: destination.icon,
                ),
                selectedIcon: _RailDestinationSemantics(
                  destination: destination,
                  label: destination.labelBuilder(l),
                  icon: destination.selectedIcon,
                ),
                label: Text(destination.labelBuilder(l)),
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
  });

  final GuardianPrimaryDestination destination;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: GuardianPrimaryDestinations.semanticsIdentifier(
        destination.route,
      ),
      button: true,
      label: label,
      child: _RailDestinationIcon(icon: icon),
    );
  }
}

/// Ensures each rail destination meets the 48×48 logical px touch target.
class _RailDestinationIcon extends StatelessWidget {
  const _RailDestinationIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 48, height: 48, child: Center(child: Icon(icon)));
  }
}
