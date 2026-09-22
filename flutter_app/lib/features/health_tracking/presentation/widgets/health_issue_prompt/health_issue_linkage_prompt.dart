import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/health_issue.dart';

/// User choice from a vet health-issue linkage prompt.
enum VetHealthIssuePromptChoice {
  dismiss,
  linkExisting,
  addNew,
  planNextVisit,
}

/// Suggested quick-pick titles for new health issues (§10.4).
enum HealthIssueQuickPick {
  injury,
  dental,
  neutering,
  other,
}

/// Lightweight sheet after unplanned vet save (§10.1).
Future<VetHealthIssuePromptChoice?> showUnplannedVetHealthIssuePrompt(
  BuildContext context,
) {
  final l = AppLocalizations.of(context)!;
  return showModalBottomSheet<VetHealthIssuePromptChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _VetHealthIssuePromptSheet(
      title: l.vetHealthIssuePromptTitle,
      primaryAction: _PromptAction(
        label: l.vetHealthIssuePromptLinkExisting,
        choice: VetHealthIssuePromptChoice.linkExisting,
      ),
      secondaryAction: _PromptAction(
        label: l.vetHealthIssuePromptAddNew,
        choice: VetHealthIssuePromptChoice.addNew,
      ),
      dismissAction: _PromptAction(
        label: l.vetHealthIssuePromptNotRelated,
        choice: VetHealthIssuePromptChoice.dismiss,
      ),
    ),
  );
}

/// Sheet after planned vet visit completion (§10.2).
Future<VetHealthIssuePromptChoice?> showPlannedVetCompletionHealthIssuePrompt(
  BuildContext context,
) {
  final l = AppLocalizations.of(context)!;
  return showModalBottomSheet<VetHealthIssuePromptChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _VetHealthIssuePromptSheet(
      title: l.vetPlannedCompletionHealthIssuePromptTitle,
      primaryAction: _PromptAction(
        label: l.vetHealthIssuePromptAddNew,
        choice: VetHealthIssuePromptChoice.addNew,
      ),
      secondaryAction: _PromptAction(
        label: l.vetHealthIssuePromptLinkExisting,
        choice: VetHealthIssuePromptChoice.linkExisting,
      ),
      dismissAction: _PromptAction(
        label: l.vetHealthIssuePromptNo,
        choice: VetHealthIssuePromptChoice.dismiss,
      ),
      extraAction: _PromptAction(
        label: l.vetHealthIssuePlanNextVisit,
        choice: VetHealthIssuePromptChoice.planNextVisit,
      ),
    ),
  );
}

class _PromptAction {
  const _PromptAction({required this.label, required this.choice});

  final String label;
  final VetHealthIssuePromptChoice choice;
}

class _VetHealthIssuePromptSheet extends StatelessWidget {
  const _VetHealthIssuePromptSheet({
    required this.title,
    required this.primaryAction,
    required this.secondaryAction,
    required this.dismissAction,
    this.extraAction,
  });

  final String title;
  final _PromptAction primaryAction;
  final _PromptAction secondaryAction;
  final _PromptAction dismissAction;
  final _PromptAction? extraAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton(
              key: Key('vet_health_issue_prompt_${primaryAction.choice.name}'),
              onPressed: () => Navigator.pop(context, primaryAction.choice),
              child: Text(primaryAction.label),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: Key('vet_health_issue_prompt_${secondaryAction.choice.name}'),
              onPressed: () => Navigator.pop(context, secondaryAction.choice),
              child: Text(secondaryAction.label),
            ),
            if (extraAction != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                key: Key('vet_health_issue_prompt_${extraAction!.choice.name}'),
                onPressed: () => Navigator.pop(context, extraAction!.choice),
                child: Text(extraAction!.label),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              key: Key('vet_health_issue_prompt_${dismissAction.choice.name}'),
              onPressed: () => Navigator.pop(context, dismissAction.choice),
              child: Text(dismissAction.label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Picker sheet for linking an existing health issue.
Future<HealthIssue?> showHealthIssuePickerSheet(
  BuildContext context,
  List<HealthIssue> issues,
) {
  final l = AppLocalizations.of(context)!;
  return showModalBottomSheet<HealthIssue>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l.healthIssueSelectTitle,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: issues.length,
                itemBuilder: (context, index) {
                  final issue = issues[index];
                  return ListTile(
                    key: Key('health_issue_pick_${issue.id}'),
                    title: Text(issue.title),
                    subtitle: issue.description.trim().isEmpty
                        ? null
                        : Text(
                            issue.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    onTap: () => Navigator.pop(context, issue),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Create-health-issue sheet with optional quick-pick chips (§10.4).
Future<({String title, String description})?> showAddHealthIssueFromVetPrompt(
  BuildContext context, {
  String? initialTitle,
}) {
  final l = AppLocalizations.of(context)!;
  final titleController = TextEditingController(text: initialTitle ?? '');
  final descController = TextEditingController();
  HealthIssueQuickPick? selectedQuickPick;

  String quickPickTitle(HealthIssueQuickPick pick) {
    switch (pick) {
      case HealthIssueQuickPick.injury:
        return l.healthIssueQuickPickInjury;
      case HealthIssueQuickPick.dental:
        return l.healthIssueQuickPickDental;
      case HealthIssueQuickPick.neutering:
        return l.healthIssueQuickPickNeutering;
      case HealthIssueQuickPick.other:
        return l.healthIssueQuickPickOther;
    }
  }

  return showModalBottomSheet<({String title, String description})>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.addHealthIssue,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: HealthIssueQuickPick.values.map((pick) {
                      return ChoiceChip(
                        key: Key('health_issue_quick_pick_${pick.name}'),
                        label: Text(quickPickTitle(pick)),
                        selected: selectedQuickPick == pick,
                        onSelected: (selected) {
                          setState(() {
                            selectedQuickPick = selected ? pick : null;
                            if (selected && pick != HealthIssueQuickPick.other) {
                              titleController.text = quickPickTitle(pick);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('vet_health_issue_title_field'),
                    controller: titleController,
                    decoration: InputDecoration(labelText: l.issueTitle),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('vet_health_issue_desc_field'),
                    controller: descController,
                    decoration: InputDecoration(labelText: l.issueDescription),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('vet_health_issue_save_button'),
                    onPressed: () {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;
                      final description = descController.text.trim().isEmpty
                          ? title
                          : descController.text.trim();
                      Navigator.pop(context, (title: title, description: description));
                    },
                    child: Text(l.save),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
