import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/care_family.dart';
import '../../../pet_profile/presentation/widgets/care_family_labels.dart';

/// Dismissible suggestion for assigning a care family on legacy uncategorised edits.
class CareFamilySuggestionBanner extends StatelessWidget {
  const CareFamilySuggestionBanner({
    super.key,
    required this.suggestedFamily,
    required this.onAccept,
    required this.onChooseDifferent,
    required this.onDismiss,
  });

  final CareFamily suggestedFamily;
  final VoidCallback onAccept;
  final VoidCallback onChooseDifferent;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final familyLabel = careFamilyLabel(l10n, suggestedFamily);

    return Semantics(
      label: l10n.careFamilySuggestionSemanticLabel(familyLabel),
      child: Material(
        key: const Key('care_family_suggestion_banner'),
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.careFamilySuggestionTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.careFamilySuggestionMessage(familyLabel),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('care_family_suggestion_dismiss'),
                    tooltip: l10n.careFamilySuggestionDismiss,
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    key: const Key('care_family_suggestion_accept'),
                    onPressed: onAccept,
                    child: Text(l10n.careFamilySuggestionAccept),
                  ),
                  TextButton(
                    key: const Key('care_family_suggestion_choose'),
                    onPressed: onChooseDifferent,
                    child: Text(l10n.careFamilySuggestionChooseDifferent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
