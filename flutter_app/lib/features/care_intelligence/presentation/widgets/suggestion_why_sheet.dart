import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

Future<void> showSuggestionWhySheet(
  BuildContext context, {
  required String rationaleKey,
  required String routineName,
  String? petName,
  String? cadenceLabel,
}) {
  final l = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final body = _rationaleText(l, rationaleKey);
  final hasPetName = petName != null && petName.isNotEmpty;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.careSuggestionWhyTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (hasPetName)
            Text(
              l.careSuggestionWhyForPet(petName),
              style: theme.textTheme.titleSmall,
            ),
          Text(
            cadenceLabel == null
                ? routineName
                : l.careSuggestionWhyRoutineSummary(routineName, cadenceLabel),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    ),
  );
}

String _rationaleText(AppLocalizations l, String rationaleKey) {
  return switch (rationaleKey) {
    'careSuggestionWeightMonitoringWhy' => l.careSuggestionWeightMonitoringWhy,
    'careSuggestionDentalWhy' => l.careSuggestionDentalWhy,
    'careSuggestionWellnessWhy' => l.careSuggestionWellnessWhy,
    _ => l.careSuggestionGenericWhy,
  };
}
