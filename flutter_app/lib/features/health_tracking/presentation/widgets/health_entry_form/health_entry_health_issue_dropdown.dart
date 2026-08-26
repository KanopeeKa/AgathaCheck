import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../providers/health_issue_providers.dart';

/// Optional health-issue link when exactly one pet is selected.
class HealthEntryHealthIssueDropdown extends ConsumerWidget {
  const HealthEntryHealthIssueDropdown({
    super.key,
    required this.petId,
    required this.selectedHealthIssueId,
    required this.onChanged,
  });

  final String petId;
  final String? selectedHealthIssueId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final issuesAsync = ref.watch(healthIssueNotifierProvider(petId));

    return issuesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (issues) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String?>(
              key: const Key('health_issue_dropdown'),
              initialValue: selectedHealthIssueId,
              decoration: InputDecoration(labelText: l.healthIssueOptional),
              items: [
                DropdownMenuItem<String?>(value: null, child: Text(l.none)),
                ...issues.map(
                  (issue) => DropdownMenuItem<String?>(
                    value: issue.id,
                    child: Text(issue.title),
                  ),
                ),
              ],
              onChanged: onChanged,
            ),
            if (issues.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  l.createHealthIssuesHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
