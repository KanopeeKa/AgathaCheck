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

Color personAccentColor(String stableId, ColorScheme scheme) {
  final candidates = <Color>[
    scheme.primary,
    scheme.secondary,
    scheme.tertiary,
    scheme.primaryContainer,
  ];
  final index = stableId.hashCode.abs() % candidates.length;
  return candidates[index];
}
