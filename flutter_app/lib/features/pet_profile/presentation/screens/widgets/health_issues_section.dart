import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/pet.dart';
import '../../../../health_tracking/domain/entities/health_issue.dart';
import '../../../../health_tracking/presentation/providers/health_issue_providers.dart';
import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';

class HealthIssuesSection extends ConsumerStatefulWidget {
  const HealthIssuesSection({required this.petId, this.pet, super.key});

  final String petId;
  final Pet? pet;

  @override
  ConsumerState<HealthIssuesSection> createState() => _HealthIssuesSectionState();
}

class _HealthIssuesSectionState extends ConsumerState<HealthIssuesSection> {
  Future<void> _showAddIssueDialog() async {
    final l = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.addIssue),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(labelText: l.issueTitle),
                validator: (v) => (v == null || v.trim().isEmpty) ? l.issueTitleRequired : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: descController,
                decoration: InputDecoration(labelText: l.issueDescription),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(l.save),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final issue = HealthIssue(
        id: const Uuid().v4(),
        petId: widget.petId,
        title: titleController.text.trim(),
        description: descController.text.trim(),
        startDate: calendarDateOnly(DateTime.now()),
      );
      await ref.read(healthIssueNotifierProvider(widget.petId).notifier).create(issue);
    }

    titleController.dispose();
    descController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final issuesAsync = ref.watch(healthIssueNotifierProvider(widget.petId));
    final l = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd();

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
                      onPressed: _showAddIssueDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l.addIssue),
                    ),
                  ),
                ],
              ),
            ),
            issuesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(e.toString(), style: TextStyle(color: colorScheme.error)),
              ),
              data: (issues) {
                if (issues.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l.noEntriesYet,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: issues.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final issue = issues[index];
                    return ListTile(
                      title: Text(issue.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (issue.description.isNotEmpty)
                            Text(issue.description),
                          if (issue.startDate != null)
                            Text(
                              dateFormat.format(issue.startDate!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: colorScheme.error),
                        onPressed: () async {
                          await ref
                              .read(healthIssueNotifierProvider(widget.petId).notifier)
                              .deleteIssue(issue.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
