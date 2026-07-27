import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_issue.dart';
import '../../../pet_profile/presentation/controllers/health_issues_controller.dart';
import 'entry_date_picker_field.dart';
import 'health_issue_documents_strip.dart';
import 'health_issue_linked_events_strip.dart';

class HealthIssueDescriptionPreview extends StatelessWidget {
  const HealthIssueDescriptionPreview({
    super.key,
    required this.text,
    required this.expanded,
    required this.cardExpanded,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final bool cardExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          maxLines: expanded ? null : 5,
          overflow: expanded ? null : TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (!cardExpanded &&
            !expanded &&
            (text.split('\n').length > 5 || text.length > 200))
          TextButton(
            onPressed: onToggle,
            child: Text(l.showMore),
          ),
      ],
    );
  }
}

class HealthIssueReadBody extends StatelessWidget {
  const HealthIssueReadBody({
    super.key,
    required this.issue,
    required this.isResolved,
    required this.onEdit,
    required this.onReopen,
    required this.petId,
    required this.controller,
  });

  final HealthIssue issue;
  final bool isResolved;
  final VoidCallback onEdit;
  final VoidCallback onReopen;
  final String petId;
  final HealthIssuesController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                issue.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: l.editIssue,
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
          ],
        ),
        if (issue.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(issue.description),
        ],
        const SizedBox(height: 12),
        HealthIssueStatusRow(isResolved: isResolved),
        const SizedBox(height: 8),
        if (issue.startDate != null)
          Text('${l.issueSince}: ${dateFormat.format(issue.startDate!)}'),
        if (issue.endDate != null)
          Text('${l.issueResolved}: ${dateFormat.format(issue.endDate!)}'),
        if (isResolved) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onReopen,
            child: Text(l.reopenIssue),
          ),
        ],
        const SizedBox(height: 16),
        HealthIssueDocumentsStrip(
          petId: petId,
          issueId: issue.id,
          controller: controller,
        ),
        const SizedBox(height: 16),
        HealthIssueLinkedEventsStrip(
          petId: petId,
          issue: issue,
          controller: controller,
        ),
      ],
    );
  }
}

class HealthIssueStatusRow extends StatelessWidget {
  const HealthIssueStatusRow({super.key, required this.isResolved});

  final bool isResolved;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final label = isResolved ? l.issueStatusResolved : l.issueStatusOpen;
    final color = isResolved ? colorScheme.outline : colorScheme.primary;

    return Row(
      children: [
        Text(
          '${l.issueStatusLabel}: ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class HealthIssueEditBody extends StatelessWidget {
  const HealthIssueEditBody({
    super.key,
    required this.titleController,
    required this.descController,
    required this.startDate,
    required this.endDate,
    required this.isResolved,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onSave,
    required this.onCancel,
    required this.onDelete,
  });

  final TextEditingController titleController;
  final TextEditingController descController;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isResolved;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final today = calendarDateOnly(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: titleController,
          decoration: InputDecoration(labelText: l.issueTitle),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: descController,
          decoration: InputDecoration(labelText: l.issueDescription),
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        EntryDatePickerField(
          label: l.issueSince,
          date: startDate,
          onChanged: onStartDateChanged,
          allowClear: true,
        ),
        const SizedBox(height: 8),
        Semantics(
          label: l.issueResolved,
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: endDate ?? today,
                firstDate: DateTime(2020),
                lastDate: today,
              );
              if (picked != null) {
                onEndDateChanged(calendarDateOnly(picked));
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l.issueResolved,
                suffixIcon: endDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: l.clear,
                        onPressed: () => onEndDateChanged(null),
                      )
                    : null,
              ),
              child: Text(
                endDate != null
                    ? DateFormat.yMMMd().format(endDate!)
                    : l.notSet,
                style: endDate == null
                    ? TextStyle(color: Theme.of(context).hintColor)
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        HealthIssueStatusRow(isResolved: isResolved),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                child: Text(l.cancel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: onSave,
                child: Text(l.save),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onDelete,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(l.deleteIssue),
        ),
      ],
    );
  }
}
