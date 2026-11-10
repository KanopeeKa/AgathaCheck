import 'package:flutter/material.dart';

/// Two-character initials from a person's display name (first + last word).
String personMonogramFromName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  final word = parts.first.replaceAll(RegExp(r'[^\w]'), '');
  if (word.isEmpty) return '?';
  if (word.length >= 2) {
    return word.substring(0, 2).toUpperCase();
  }
  return word[0].toUpperCase();
}

/// Ring/tint and glyph colors for [PersonAvatar] placeholders.
class PersonMonogramStyle {
  const PersonMonogramStyle({required this.accent, required this.foreground});

  /// Drives the circular tint and ring — never the initials glyph.
  final Color accent;

  /// Initials on the tinted circle (paired `on*Container` per accent family).
  final Color foreground;
}

PersonMonogramStyle personMonogramStyle(String stableId, ColorScheme scheme) {
  PersonMonogramStyle slot(int i) {
    switch (i) {
      case 0:
        return PersonMonogramStyle(
          accent: scheme.primary,
          foreground: scheme.onPrimaryContainer,
        );
      case 1:
        return PersonMonogramStyle(
          accent: scheme.secondary,
          foreground: scheme.onSecondaryContainer,
        );
      case 2:
      default:
        return PersonMonogramStyle(
          accent: scheme.tertiary,
          foreground: scheme.onTertiaryContainer,
        );
    }
  }

  final index = stableId.hashCode.abs() % 3;
  return slot(index);
}
