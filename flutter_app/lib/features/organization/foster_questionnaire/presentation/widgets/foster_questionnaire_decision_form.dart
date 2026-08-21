import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/foster_questionnaire_review.dart';
import '../providers/foster_questionnaire_review_providers.dart';

class FosterQuestionnaireDecisionForm extends StatefulWidget {
  const FosterQuestionnaireDecisionForm({
    super.key,
    required this.onSubmit,
    this.busy = false,
    this.previousDecisions = const [],
  });

  final Future<void> Function({
    required String decision,
    required String structuredReason,
    String staffNotes,
  })
  onSubmit;
  final bool busy;
  final List<FosterQuestionnaireDecision> previousDecisions;

  @override
  State<FosterQuestionnaireDecisionForm> createState() =>
      _FosterQuestionnaireDecisionFormState();
}

class _FosterQuestionnaireDecisionFormState
    extends State<FosterQuestionnaireDecisionForm> {
  final _formKey = GlobalKey<FormState>();
  final _structuredReasonController = TextEditingController();
  final _staffNotesController = TextEditingController();
  String? _selectedDecision;

  @override
  void dispose() {
    _structuredReasonController.dispose();
    _staffNotesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSubmit(
      decision: _selectedDecision!,
      structuredReason: _structuredReasonController.text.trim(),
      staffNotes: _staffNotesController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.previousDecisions.isNotEmpty) ...[
            Text(
              l.fosterQuestionnairePreviousDecisionsTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.previousDecisions.map(
              (decision) => _PreviousDecisionTile(decision: decision),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            l.fosterQuestionnaireRecordDecisionTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const Key('foster_questionnaire_decision_dropdown'),
            initialValue: _selectedDecision,
            decoration: InputDecoration(
              labelText: l.fosterQuestionnaireDecisionLabel,
              border: const OutlineInputBorder(),
            ),
            items: fosterQuestionnaireDecisionLabels
                .map(
                  (label) => DropdownMenuItem(
                    value: label,
                    child: Text(
                      localizedFosterQuestionnaireDecisionLabel(l, label),
                    ),
                  ),
                )
                .toList(),
            onChanged: widget.busy
                ? null
                : (value) => setState(() => _selectedDecision = value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l.fosterQuestionnaireDecisionRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('foster_questionnaire_structured_reason'),
            controller: _structuredReasonController,
            enabled: !widget.busy,
            decoration: InputDecoration(
              labelText: l.fosterQuestionnaireStructuredReasonLabel,
              border: const OutlineInputBorder(),
            ),
            minLines: 3,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l.fosterQuestionnaireStructuredReasonRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('foster_questionnaire_staff_notes'),
            controller: _staffNotesController,
            enabled: !widget.busy,
            decoration: InputDecoration(
              labelText: l.fosterQuestionnaireStaffNotesLabel,
              border: const OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('foster_questionnaire_submit_decision'),
            onPressed: widget.busy ? null : _submit,
            icon: widget.busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(l.fosterQuestionnaireSubmitDecision),
          ),
        ],
      ),
    );
  }
}

class _PreviousDecisionTile extends StatelessWidget {
  const _PreviousDecisionTile({required this.decision});

  final FosterQuestionnaireDecision decision;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          localizedFosterQuestionnaireDecisionLabel(l, decision.decision),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(decision.structuredReason),
            if (decision.staffNotes.isNotEmpty) Text(decision.staffNotes),
            if (decision.decidedAt != null)
              Text(
                decision.decidedAt!,
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
