import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/pet.dart';
import '../../../health_tracking/presentation/providers/health_issue_providers.dart';
import '../../../../l10n/app_localizations.dart';

class HealthIssuesSection extends ConsumerStatefulWidget {
  const HealthIssuesSection({required this.petId, this.pet, super.key});

  final String petId;
  final Pet? pet;

    final controller = HealthIssuesController(ref);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
class _HealthIssuesSectionState extends ConsumerState<HealthIssuesSection> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final issuesAsync = ref.watch(healthIssueNotifierProvider(widget.petId));
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: Icon(Icons.health_and_safety, color: colorScheme.primary),
          title: Text(l.healthIssues,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: l.addIssue,
                    child: FilledButton.tonalIcon(
                      key: const Key('add_health_issue_button'),
                      onPressed: () {}, // TODO: Implement
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l.addIssue),
                    ),
                  ),
                ],
              ),
            ),
            // ...rest of the health issues UI...
          ],
        ),
      ),
    );
  }
}
