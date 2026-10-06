import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../config/pet_care_primary_destinations.dart';
import '../providers/care_actions_attention_provider.dart';
import 'pet_care_nav_attention_badge.dart';

/// Primary Guardian destinations on compact and touch-first screens.
///
/// Shelter switching stays in the shared drawer; this bar only exposes the
/// Guardian work a person performs most often.
class PetCareBottomNavigation extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final attentionCount = ref.watch(careActionsAttentionCountProvider);
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
                attentionCount: destination.route == '/pc/events'
                    ? attentionCount
                    : 0,
              ),
              activeIcon: _BottomNavDestinationIcon(
                destination: destination,
                label: destination.labelBuilder(l),
                selected: true,
                attentionCount: destination.route == '/pc/events'
                    ? attentionCount
                    : 0,
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
    required this.attentionCount,
  });

  final PetCarePrimaryDestination destination;
  final String label;
  final bool selected;
  final int attentionCount;

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
          child: PetCareNavAttentionBadge(
            count: attentionCount,
            child: Icon(icon, size: PetCareBottomNavigation.bottomNavIconSize),
          ),
        ),
      ),
    );
  }
}
