import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/planned_absence.dart';
import '../providers/care_context_providers.dart';

class AwayPlanHandoverNoteSection extends ConsumerStatefulWidget {
  const AwayPlanHandoverNoteSection({super.key, required this.absence});

  final PlannedAbsence absence;

  @override
  ConsumerState<AwayPlanHandoverNoteSection> createState() =>
      _AwayPlanHandoverNoteSectionState();
}

class _AwayPlanHandoverNoteSectionState
    extends ConsumerState<AwayPlanHandoverNoteSection> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.absence.handoverNote ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await ref
          .read(careContextRepositoryProvider)
          .updateHandoverNote(
            absenceId: widget.absence.id,
            handoverNote: _controller.text.trim().isEmpty
                ? null
                : _controller.text,
          );
      ref.invalidate(plannedAbsenceDetailProvider(widget.absence.id));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.careContextAwaySaveSuccess)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.careContextAwaySaveFailed)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.pdfNotesLabel, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('away_plan_handover_note'),
                  controller: _controller,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: l.pdfNotesLabel,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l.careContextAwaySaveAction),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
