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

/// Expanded leading sidebar for Guardian workspace on wide screens (≥840px).
class GuardianNavigationSidebar extends ConsumerWidget {
  const GuardianNavigationSidebar({super.key, required this.currentLocation});

  static const width = 240.0;

  final String currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final destinations = GuardianPrimaryDestinations.destinations();
    final primaryDestinations = destinations.take(4).toList();
    final accountDestination = destinations[4];
    final selectedIndex = GuardianPrimaryDestinations.indexFor(currentLocation);
    final isRoot = DrawerMenuConfig.sectionRootPaths.contains(currentLocation);
    final showShelterWorkspace =
        isRoot &&
        (currentLocation.startsWith('/o/') ||
            ref.watch(showOrganisationSectionProvider));

    return Semantics(
      identifier: 'guardian_navigation_sidebar',
      container: true,
      child: SizedBox(
        key: const Key('guardian_navigation_sidebar'),
        width: width,
        child: ColoredBox(
          color: AppColorTokens.background,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppLogoTitle(
                        title: l.appTitle,
                        experience: AppExperience.guardian,
                        linkLogo: false,
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
                  selected: selectedIndex == 4,
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

  final GuardianPrimaryDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final label = destination.labelBuilder(l);
    final icon = selected ? destination.selectedIcon : destination.icon;
    final color = selected
        ? AppColorTokens.guardianPrimary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected
            ? AppColorTokens.guardianPrimary.withValues(alpha: 0.08)
            : Colors.transparent,
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
                        color: AppColorTokens.guardianPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  else
                    const SizedBox(width: 12),
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
