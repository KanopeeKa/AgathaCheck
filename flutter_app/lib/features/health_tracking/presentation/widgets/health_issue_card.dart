import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_issue.dart';
import '../../presentation/providers/health_issue_providers.dart';
import '../../../pet_profile/presentation/controllers/health_issues_controller.dart';
import 'health_issue_card_body.dart';

class HealthIssueCard extends ConsumerStatefulWidget {
  const HealthIssueCard({
    super.key,
    required this.petId,
    required this.issue,
    required this.controller,
    this.initiallyExpanded = false,
  });

  final String petId;
  final HealthIssue issue;
  final HealthIssuesController controller;
  final bool initiallyExpanded;

  @override
  ConsumerState<HealthIssueCard> createState() => _HealthIssueCardState();
}

class _HealthIssueCardState extends ConsumerState<HealthIssueCard> {
  late bool _expanded;
  bool _descriptionExpanded = false;
  bool _editing = false;
  late TextEditingController _titleController;
  late TextEditingController _descController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _initEditFields(widget.issue);
  }

  @override
  void didUpdateWidget(covariant HealthIssueCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.issue.id != widget.issue.id ||
        (!_editing && oldWidget.issue != widget.issue)) {
      _initEditFields(widget.issue);
    }
  }

  void _initEditFields(HealthIssue issue) {
    _titleController = TextEditingController(text: issue.title);
    _descController = TextEditingController(text: issue.description);
    _startDate = issue.startDate;
    _endDate = issue.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _isResolved => widget.controller.isResolved(widget.issue);

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  void _startEditing() {
    _initEditFields(widget.issue);
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    _initEditFields(widget.issue);
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.issueTitleRequired)));
      return;
    }

    final updated = widget.issue.copyWith(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      clearStartDate: _startDate == null,
      clearEndDate: _endDate == null,
    );

    await widget.controller.saveIssue(widget.petId, updated);
    if (mounted) setState(() => _editing = false);
  }

  Future<void> _delete() async {
    final confirmed = await widget.controller.confirmDeleteIssue(context);
    if (!confirmed || !mounted) return;
    await widget.controller.deleteIssue(widget.petId, widget.issue.id);
  }

  Future<void> _reopen() async {
    final l = AppLocalizations.of(context)!;
    final reopened = widget.controller.reopenIssue(widget.issue, l);
    await widget.controller.saveIssue(widget.petId, reopened);
    if (mounted) {
      _initEditFields(reopened);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();
    final docsAsync = ref.watch(healthIssueDocumentsProvider(widget.issue.id));
    final hasDocuments = docsAsync.maybeWhen(
      data: (docs) => docs.isNotEmpty,
      orElse: () => false,
    );
    final displayDate = widget.controller.displayDate(widget.issue, dateFormat);

    return Card(
      key: Key('health_issue_card_${widget.issue.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: Key('health_issue_header_${widget.issue.id}'),
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.issue.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.issue.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          HealthIssueDescriptionPreview(
                            text: widget.issue.description,
                            expanded: _descriptionExpanded || _expanded,
                            cardExpanded: _expanded,
                            onToggle: () => setState(
                              () =>
                                  _descriptionExpanded = !_descriptionExpanded,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (displayDate.isNotEmpty)
                        Text(
                          displayDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (hasDocuments)
                        Icon(
                          Icons.attach_file,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _editing
                  ? HealthIssueEditBody(
                      titleController: _titleController,
                      descController: _descController,
                      startDate: _startDate,
                      endDate: _endDate,
                      isResolved: _endDate != null,
                      onStartDateChanged: (d) => setState(() => _startDate = d),
                      onEndDateChanged: (d) => setState(() => _endDate = d),
                      onSave: _save,
                      onCancel: _cancelEditing,
                      onDelete: _delete,
                    )
                  : HealthIssueReadBody(
                      issue: widget.issue,
                      isResolved: _isResolved,
                      onEdit: _startEditing,
                      onReopen: _reopen,
                      petId: widget.petId,
                      controller: widget.controller,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
