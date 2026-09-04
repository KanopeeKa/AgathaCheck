import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_experience.dart';
import '../config/shelter_primary_destinations.dart';
import 'experience_workspace_toggle.dart';

/// Expanded leading sidebar for Shelter workspace on wide screens (≥840px).
class ShelterNavigationSidebar extends ConsumerWidget {
  const ShelterNavigationSidebar({
    super.key,
    required this.currentLocation,
    this.pinnedOrg,
  });

  static const width = 240.0;

  final String currentLocation;
  final ShelterPinnedOrganization? pinnedOrg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final destinations = ShelterPrimaryDestinations.navigableDestinations(
      pinnedOrg: pinnedOrg,
    );
    final primaryDestinations = destinations.sublist(
      0,
      destinations.length - 1,
    );
    final accountDestination = destinations.last;
    final selectedIndex = ShelterPrimaryDestinations.navigableIndexFor(
      currentLocation,
      pinnedOrg: pinnedOrg,
    );

    return Semantics(
      identifier: 'shelter_navigation_sidebar',
      container: true,
      child: SizedBox(
        key: const Key('shelter_navigation_sidebar'),
        width: width,
        child: ColoredBox(
          color: AppColorTokens.surface,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppLogoTitle(
                        title: l.appTitle,
                        experience: AppExperience.organization,
                        linkLogo: false,
                      ),
                      const SizedBox(height: 12),
                      ExperienceWorkspaceToggle(
                        currentLocation: currentLocation,
                        onDarkBackground: false,
                        showShelter: true,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      for (var i = 0; i < primaryDestinations.length; i++)
                        _SidebarDestinationTile(
                          destination: primaryDestinations[i],
                          selected: selectedIndex == i,
                          onTap: () => context.go(primaryDestinations[i].route),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _SidebarDestinationTile(
                  destination: accountDestination,
                  selected: selectedIndex == primaryDestinations.length,
                  onTap: () => context.go(accountDestination.route),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarDestinationTile extends StatelessWidget {
  const _SidebarDestinationTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ShelterPrimaryDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final label = destination.labelBuilder(l);
    final icon = selected ? destination.selectedIcon : destination.icon;
    final color = selected
        ? AppColorTokens.organizationPrimary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final pinned = destination.pinnedOrg;

    return Semantics(
      identifier: ShelterPrimaryDestinations.semanticsIdentifier(
        destination.route,
      ),
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  if (selected)
                    Container(
                      width: 3,
                      height: 40,
                      margin: const EdgeInsets.only(right: 9),
                      decoration: BoxDecoration(
                        color: AppColorTokens.organizationPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  else
                    const SizedBox(width: 12),
                  if (pinned != null && pinned.logoUrl.isNotEmpty)
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColorTokens.organizationSoft,
                      backgroundImage: NetworkImage(pinned.logoUrl),
                    )
                  else
                    Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
