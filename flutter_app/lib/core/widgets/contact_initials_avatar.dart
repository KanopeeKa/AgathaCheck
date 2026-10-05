import 'package:flutter/material.dart';

/// Circular initials avatar shared by People and Vet directory cards.
class ContactInitialsAvatar extends StatelessWidget {
  const ContactInitialsAvatar({
    super.key,
    required this.name,
    this.organizationId,
  });

  final String name;
  final String? organizationId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(name);
    final color = organizationId == null
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.secondaryContainer;
    final onColor = organizationId == null
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSecondaryContainer;

    return CircleAvatar(
      backgroundColor: color,
      foregroundColor: onColor,
      child: Text(
        initials,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }
}
