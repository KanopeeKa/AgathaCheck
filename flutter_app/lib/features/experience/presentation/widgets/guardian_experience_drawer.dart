import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'experience_section_drawer.dart';

/// Guardian experience hamburger menu.
///
/// Superseded by [ExperienceSectionDrawer] (navigation reversal, phase-1-navigation.md).
/// Kept as a forward-compat shim — use [ExperienceSectionDrawer] directly.
class GuardianExperienceDrawer extends ConsumerWidget {
  const GuardianExperienceDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ExperienceSectionDrawer();
  }
}
