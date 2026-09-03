import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../config/shelter_primary_destinations.dart';

/// Primary Shelter destinations on compact and touch-first screens.
class ShelterBottomNavigation extends StatelessWidget {
  const ShelterBottomNavigation({
    super.key,
    required this.currentLocation,
    this.pinnedOrg,
  });

  final String currentLocation;
  final ShelterPinnedOrganization? pinnedOrg;

  static const compactBreakpoint =
      ShelterPrimaryDestinations.compactBreakpoint;

  static bool isCompact(double width) =>
      ShelterPrimaryDestinations.isCompact(width);

  static bool supports(String path) => ShelterPrimaryDestinations.supports(path);

  static int indexFor(String path, {ShelterPinnedOrganization? pinnedOrg}) =>
      ShelterPrimaryDestinations.indexFor(path, pinnedOrg: pinnedOrg);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final navSlots = ShelterPrimaryDestinations.slots(pinnedOrg: pinnedOrg);
    final selectedIndex = ShelterPrimaryDestinations.indexFor(
      currentLocation,
      pinnedOrg: pinnedOrg,
    );

    return SafeArea(
      top: false,
      child: BottomNavigationBar(
        key: const Key('shelter_bottom_navigation'),
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        backgroundColor: AppColorTokens.organizationPrimary,
        selectedItemColor: AppColorTokens.inverse,
        unselectedItemColor: AppColorTokens.organizationLight,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        onTap: (index) {
          final route = navSlots[index].route;
          if (route != null) context.go(route);
        },
        items: [
          for (final slot in navSlots) _buildBarItem(context, l, slot),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildBarItem(
    BuildContext context,
    AppLocalizations l,
    ShelterNavSlot slot,
  ) {
    switch (slot.kind) {
      case ShelterNavSlotKind.spacer:
        return const BottomNavigationBarItem(
          icon: _ShelterNavSpacerIcon(),
          label: '',
        );
      case ShelterNavSlotKind.hidden:
        return const BottomNavigationBarItem(
          icon: SizedBox(width: 24, height: 24),
          label: '',
        );
      case ShelterNavSlotKind.destination:
        final destination = slot.destination!;
        final label = destination.labelBuilder(l);
        final icon = _ShelterDestinationIcon(
          destination: destination,
          selected: false,
        );
        final activeIcon = _ShelterDestinationIcon(
          destination: destination,
          selected: true,
        );
        return BottomNavigationBarItem(
          icon: icon,
          activeIcon: activeIcon,
          label: label,
        );
    }
  }
}

class _ShelterNavSpacerIcon extends StatelessWidget {
  const _ShelterNavSpacerIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 24,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColorTokens.organizationLight,
        ),
      ),
    );
  }
}

class _ShelterDestinationIcon extends StatelessWidget {
  const _ShelterDestinationIcon({
    required this.destination,
    required this.selected,
  });

  final ShelterPrimaryDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final pinned = destination.pinnedOrg;
    final icon = selected ? destination.selectedIcon : destination.icon;
    if (pinned != null && pinned.logoUrl.isNotEmpty) {
      return Semantics(
        identifier: ShelterPrimaryDestinations.semanticsIdentifier(
          destination.route,
        ),
        child: CircleAvatar(
          radius: 12,
          backgroundColor: AppColorTokens.organizationLight,
          backgroundImage: NetworkImage(pinned.logoUrl),
        ),
      );
    }
    return Semantics(
      identifier: ShelterPrimaryDestinations.semanticsIdentifier(
        destination.route,
      ),
      child: Icon(icon),
    );
  }
}
