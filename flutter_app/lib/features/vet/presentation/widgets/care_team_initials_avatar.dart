import 'package:flutter/material.dart';

import '../utils/care_team_initials.dart';
import '../utils/vet_accent.dart';

/// Circular initials avatar for a care team / veterinary clinic.
///
/// When [imageUrl] is provided in the future, it replaces the initials monogram.
class CareTeamInitialsAvatar extends StatelessWidget {
  const CareTeamInitialsAvatar({
    super.key,
    required this.name,
    this.organizationId,
    this.imageUrl,
    this.radius = 22,
  });

  final String name;
  final String? organizationId;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = resolveVetAccent(context, organizationId: organizationId);
    final initials = careTeamInitialsFromName(name);
    final resolvedImage = imageUrl?.trim() ?? '';

    Widget child;
    if (resolvedImage.isNotEmpty) {
      child = ClipOval(
        child: Image.network(
          resolvedImage,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsText(theme, accent, initials),
        ),
      );
    } else {
      child = _initialsText(theme, accent, initials);
    }

    return ExcludeSemantics(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.primary.withValues(alpha: 0.14),
          border: Border.all(color: accent.primary.withValues(alpha: 0.35)),
        ),
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }

  Widget _initialsText(ThemeData theme, VetAccent accent, String initials) {
    return Text(
      initials,
      style: theme.textTheme.titleSmall?.copyWith(
        color: accent.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}
