import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/shell_return_navigation.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/care_command_outcome.dart';
import '../../application/care_item_providers.dart';
import '../../domain/care_occurrence.dart';
import '../../domain/occurrence_detail.dart';
import 'occurrence_blocks.dart';

/// One occurrence, every status (D-CIE-029, §18.6.4). Loads
/// `GET …/occurrences/:occId`; actions reload it after the server confirms.
class OccurrenceScreen extends ConsumerStatefulWidget {
  const OccurrenceScreen({
    super.key,
    required this.petId,
    required this.entryId,
    required this.occurrenceId,
    this.focus,
  });

  final String petId;
  final String entryId;
  final String occurrenceId;

  /// `weight` focuses the weight field; `date` the date field.
  final String? focus;

  @override
  ConsumerState<OccurrenceScreen> createState() => _OccurrenceScreenState();
}

class _OccurrenceScreenState extends ConsumerState<OccurrenceScreen> {
  CareOutcome<OccurrenceDetail>? _outcome;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final outcome = await ref
        .read(careCompletionServiceProvider)
        .fetchOccurrence(
          entryId: widget.entryId,
          occurrenceId: widget.occurrenceId,
        );
    if (mounted) setState(() => _outcome = outcome);
  }

  Future<void> _changed() async {
    await ref.read(careDataChangedProvider)();
    await _load();
  }

  void _openItem() =>
      openPetEventView(context, petId: widget.petId, entryId: widget.entryId);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final outcome = _outcome;
    final title = switch (outcome) {
      CareSucceeded(:final value) => value.item.name,
      _ => '',
    };
    return Semantics(
      identifier: 'occurrence_screen',
      child: Scaffold(
        key: const Key('occurrence_screen'),
        appBar: AppBar(title: Text(title)),
        body: switch (outcome) {
          null => const Center(child: CircularProgressIndicator()),
          CareFailed(failure: CareNotOpenFailure(gone: true)) => _Message(
            key: const Key('occurrence_gone'),
            text: l.occurrenceGone,
            actionLabel: l.occurrenceAboutItem,
            onAction: _openItem,
          ),
          CareFailed() => _Message(
            key: const Key('occurrence_error'),
            text: l.careOccurrenceLoadError,
            actionLabel: l.careRetry,
            onAction: () {
              setState(() => _outcome = null);
              _load();
            },
          ),
          CareSucceeded(:final value) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Header(detail: value, onOpenItem: _openItem),
              const SizedBox(height: 16),
              OccurrenceBlocks(
                detail: value,
                focus: widget.focus,
                onChanged: _changed,
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail, required this.onOpenItem});

  final OccurrenceDetail detail;
  final VoidCallback onOpenItem;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final occ = detail.occurrence;
    final status = switch (occ.status) {
      CareOccurrenceStatus.overdue => l.urgencyOverdue,
      CareOccurrenceStatus.notRecorded => l.careStatusNotRecorded,
      CareOccurrenceStatus.due => l.careStatusDue,
      CareOccurrenceStatus.done => l.done,
      CareOccurrenceStatus.skipped => l.careSkip,
      _ => l.careStatusComingUp,
    };
    final when = [DateFormat.yMMMd().format(occ.date), ?occ.time].join(' · ');
    return Semantics(
      header: true,
      child: InkWell(
        key: const Key('occurrence_about_item'),
        onTap: onOpenItem,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail.item.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '$status · $when',
                      key: const Key('occurrence_status'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: l.occurrenceAboutItem,
                child: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
