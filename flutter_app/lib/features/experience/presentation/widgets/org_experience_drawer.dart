import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'experience_section_drawer.dart';

/// Organisation experience hamburger menu.
///
/// Superseded by [ExperienceSectionDrawer] (navigation reversal, phase-1-navigation.md).
/// Kept as a forward-compat shim — use [ExperienceSectionDrawer] directly.
class OrgExperienceDrawer extends ConsumerWidget {
  const OrgExperienceDrawer({
    super.key,
    required this.showGuardianView,
    required this.isFosterPortal,
  });

  // Retained for call-site compatibility; ignored in the unified drawer.
  final bool showGuardianView;
  final bool isFosterPortal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ExperienceSectionDrawer();
  }
}
