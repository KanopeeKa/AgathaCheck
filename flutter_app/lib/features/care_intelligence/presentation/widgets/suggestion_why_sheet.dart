import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

Future<void> showSuggestionWhySheet(
  BuildContext context, {
  required String rationaleKey,
}) {
  final l = AppLocalizations.of(context)!;
  final body = _rationaleText(l, rationaleKey);

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.careSuggestionWhyTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
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
