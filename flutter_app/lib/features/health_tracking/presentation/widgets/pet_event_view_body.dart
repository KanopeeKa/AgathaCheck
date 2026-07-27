import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_history_entry.dart';
import '../providers/health_providers.dart';
import 'due_event_card.dart';
import 'health_entry_type_labels.dart';
import 'pet_event_administration_history_dialog.dart';
import 'pet_event_documents_strip.dart';
import 'pet_event_lifecycle.dart';
import 'pet_event_past_iterations_section.dart';
import 'pet_event_pet_card.dart';

/// Read-only body for [PetEventViewScreen].
class PetEventViewBody extends ConsumerWidget {
  const PetEventViewBody({
    super.key,
    required this.petId,
    required this.entry,
    required this.pet,
    required this.history,
    required this.isClosed,
    required this.onEdit,
    required this.onSeeHistory,
    required this.onClose,
    required this.onReopen,
  });

  final String petId;
  final HealthEntry entry;
  final Pet pet;
  final List<HealthHistoryEntry> history;
  final bool isClosed;
  final VoidCallback onEdit;
  final VoidCallback onSeeHistory;
  final VoidCallback onClose;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final muted = isClosed;
    final textColor = muted ? colorScheme.onSurfaceVariant : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PetEventPetCard(pet: pet),
          const SizedBox(height: 16),
          _TypeDosageRow(entry: entry, muted: muted),
          const SizedBox(height: 12),
          _StatusRow(isClosed: isClosed),
          const SizedBox(height: 12),
          _ActionButtons(
            isClosed: isClosed,
            onEdit: onEdit,
            onClose: onClose,
            onReopen: onReopen,
          ),
          const SizedBox(height: 16),
          Text(
            formatRecurrenceSummary(l, entry),
            style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            formatRemindSummary(l, entry),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.nextOccurrence,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          _IterationCard(
            entry: entry,
            pet: pet,
            history: history,
            isClosed: isClosed,
          ),
          if (entry.healthIssueId != null &&
              (entry.healthIssueName?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 16),
            _HealthIssueLink(
              petId: petId,
              issueName: entry.healthIssueName!,
              muted: muted,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l.notes,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.notes.isNotEmpty ? entry.notes : l.notSet,
            style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
          ),
          const SizedBox(height: 16),
          PetEventDocumentsStrip(entryId: entry.id),
          const SizedBox(height: 16),
          PetEventPastIterationsSection(
            entry: entry,
            history: history,
            isClosed: isClosed,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('pet_event_see_history_body'),
            onPressed: onSeeHistory,
            icon: const Icon(Icons.history),
            label: Text(l.seeHistory),
          ),
        ],
      ),
    );
  }
}

class _TypeDosageRow extends StatelessWidget {
  const _TypeDosageRow({required this.entry, required this.muted});

  final HealthEntry entry;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = muted
        ? colorScheme.onSurfaceVariant
        : colorScheme.primary;

    return Row(
      children: [
        Icon(healthEntryTypeIcon(entry.type), color: iconColor, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            entry.dosage.isNotEmpty
                ? '${healthEntryTypeLabel(l, entry.type)} · ${entry.dosage}'
                : healthEntryTypeLabel(l, entry.type),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: muted ? colorScheme.onSurfaceVariant : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.isClosed});

  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final label = isClosed ? l.eventStatusClosed : l.issueStatusOpen;
    final color = isClosed ? colorScheme.onSurfaceVariant : colorScheme.primary;

    return Row(
      children: [
        Text(
          '${l.issueStatusLabel}: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isClosed,
    required this.onEdit,
    required this.onClose,
    required this.onReopen,
  });

  final bool isClosed;
  final VoidCallback onEdit;
  final VoidCallback onClose;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton(
          key: const Key('pet_event_edit_button'),
          onPressed: onEdit,
          child: Text(l.edit),
        ),
        if (isClosed)
          OutlinedButton(
            key: const Key('pet_event_reopen_button'),
            onPressed: onReopen,
            child: Text(l.reopenEventAction),
          )
        else
          OutlinedButton(
            key: const Key('pet_event_close_button'),
            onPressed: onClose,
            child: Text(l.closeEventAction),
          ),
      ],
    );
  }
}

class _IterationCard extends StatelessWidget {
  const _IterationCard({
    required this.entry,
    required this.pet,
    required this.history,
    required this.isClosed,
  });

  final HealthEntry entry;
  final Pet pet;
  final List<HealthHistoryEntry> history;
  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    if (isClosed) {
      final last = sortedHistoryDesc(history).firstOrNull;
      if (last == null) {
        return Text(
          AppLocalizations.of(context)!.noHistoryYet,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      }
      return _ClosedIterationCard(historyEntry: last);
    }

    return DueEventCard(
      key: Key('pet_event_due_card_${entry.id}'),
      entry: entry,
      pet: pet,
      showActions: true,
    );
  }
}

class _ClosedIterationCard extends StatelessWidget {
  const _ClosedIterationCard({required this.historyEntry});

  final HealthHistoryEntry historyEntry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();

    final label = historyEntry.isSkipped
        ? l.occurrenceSkipped
        : historyEntry.completedOn != null
        ? l.doneOn(dateFormat.format(historyEntry.completedOn!))
        : historyEntry.dueDate != null
        ? dateFormat.format(historyEntry.dueDate!)
        : l.notSet;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _HealthIssueLink extends StatelessWidget {
  const _HealthIssueLink({
    required this.petId,
    required this.issueName,
    required this.muted,
  });

  final String petId;
  final String issueName;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.relatesToHealthIssue,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: muted ? colorScheme.onSurfaceVariant : null,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          key: const Key('pet_event_health_issue_link'),
          onTap: muted ? null : () => context.push('/pet/$petId/health-issues'),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  issueName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: muted
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> showPetEventHistory(
  BuildContext context,
  WidgetRef ref,
  String entryId,
) async {
  final l = AppLocalizations.of(context)!;
  try {
    final history = await ref.read(entryHistoryProvider(entryId).future);
    if (!context.mounted) return;
    await showPetEventAdministrationHistoryDialog(context, history: history);
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.failedToLoadHistory('$error'))));
  }
}
