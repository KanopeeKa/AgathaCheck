import 'package:flutter/material.dart';

import '../../../vet/presentation/utils/vet_team_initials.dart';

String personMonogramFromName(String name) => vetTeamInitialsFromName(name);

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
