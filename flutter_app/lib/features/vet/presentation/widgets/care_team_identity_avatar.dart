import 'package:flutter/material.dart';

import '../utils/vet_accent.dart';
import '../utils/vet_initials.dart';

/// Circular initials avatar for a care team / veterinary clinic.
class CareTeamIdentityAvatar extends StatelessWidget {
  const CareTeamIdentityAvatar({
    super.key,
    required this.name,
    required this.accent,
    this.radius = 22,
  });

  final String name;
  final VetAccent accent;

  /// Default ~44 logical px diameter, matching dashboard care team rows.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = vetInitialsFromName(name);

    return CircleAvatar(
      radius: radius,
      backgroundColor: accent.primary.withAlpha(60),
      child: Text(
        initials,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: accent.primary,
        ),
      ),
    );
  }
}
