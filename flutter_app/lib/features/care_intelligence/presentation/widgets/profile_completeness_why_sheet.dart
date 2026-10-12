import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/profile_completeness_kind.dart';

Future<void> showProfileCompletenessWhySheet(
  BuildContext context, {
  required ProfileCompletenessKind kind,
}) {
  final l = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final body = switch (kind) {
    ProfileCompletenessKind.neuter => l.profileCompletenessWhyNeuterBody,
    ProfileCompletenessKind.chip => l.profileCompletenessWhyChipBody,
  };

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
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    ),
  );
}
