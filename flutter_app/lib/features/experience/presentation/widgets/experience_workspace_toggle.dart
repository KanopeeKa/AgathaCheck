import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


/// Frozen MVP: Pet Care-only — workspace switcher removed (D-MVP-1).
class ExperienceWorkspaceToggle extends ConsumerWidget {
  const ExperienceWorkspaceToggle({
    super.key,
    required this.currentLocation,
    required this.onDarkBackground,
    required this.showShelter,
  });

  final String currentLocation;
  final bool onDarkBackground;
  final bool showShelter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }
}
