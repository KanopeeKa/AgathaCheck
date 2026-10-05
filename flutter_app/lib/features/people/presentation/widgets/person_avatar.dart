import 'package:flutter/material.dart';

import '../../domain/entities/contact_summary.dart';
import '../../domain/enums/contact_kind.dart';
import 'person_monogram.dart';

enum PersonAvatarSize { row, header }

/// Circular avatar for a person or organisation contact.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    required this.stableId,
    this.kind = ContactKind.person,
    this.photoUrl,
    this.size = PersonAvatarSize.row,
  });

  final String name;
  final String stableId;
  final ContactKind kind;
  final String? photoUrl;
  final PersonAvatarSize size;

  double get _diameter => size == PersonAvatarSize.header ? 64 : 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = personAccentColor(stableId, theme.colorScheme);
    final initials = personMonogramFromName(name);
    final resolvedPhoto = photoUrl?.trim() ?? '';

    Widget avatarChild;
    if (resolvedPhoto.isNotEmpty) {
      avatarChild = ClipOval(
        child: Image.network(
          resolvedPhoto,
          width: _diameter,
          height: _diameter,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _monogram(theme, accent, initials),
        ),
      );
    } else {
      avatarChild = _monogram(theme, accent, initials);
    }

    return Semantics(
      label: name,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _diameter,
            height: _diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            child: avatarChild,
          ),
          if (kind == ContactKind.organisation)
            Positioned(right: -2, bottom: -2, child: _OrgBadge(theme: theme)),
        ],
      ),
    );
  }

  Widget _monogram(ThemeData theme, Color accent, String initials) {
    return Text(
      initials,
      style: theme.textTheme.titleSmall?.copyWith(
        color: accent,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        fontSize: size == PersonAvatarSize.header ? 22 : 14,
      ),
    );
  }
}

class _OrgBadge extends StatelessWidget {
  const _OrgBadge({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Icon(
        Icons.business_outlined,
        size: 12,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

PersonAvatar personAvatarFromSummary(
  ContactSummary summary, {
  PersonAvatarSize size = PersonAvatarSize.row,
  String? photoUrl,
}) {
  return PersonAvatar(
    name: summary.name,
    stableId: summary.id,
    kind: summary.kind,
    photoUrl: photoUrl,
    size: size,
  );
}
