import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_history_entry.dart';
import '../providers/health_providers.dart';
import 'pet_event_administration_history_dialog.dart';
import 'pet_event_documents_strip.dart';
import 'pet_event_lifecycle.dart';
import 'pet_event_open_occurrences_section.dart';
import 'pet_event_past_occurrences_section.dart';
import 'pet_event_past_iterations_section.dart';
import 'pet_event_pet_card.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import 'health_entry_type_labels.dart';

/// Read-only body for [PetEventViewScreen] with occurrence workbench actions.
class PetEventViewBody extends ConsumerWidget {
  const PetEventViewBody({
    super.key,
    required this.petId,
    required this.entry,
    required this.pet,
    required this.history,
    required this.isClosed,
    required this.onSeeHistory,
    required this.onClose,
    required this.onReopen,
  });

  final String petId;
  final HealthEntry entry;
  final Pet pet;
  final List<HealthHistoryEntry> history;
  final bool isClosed;
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
    final showOccurrenceWorkbench = !isClosed && !entry.isCompleted;

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
          _LifecycleActions(
            isClosed: isClosed,
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
          if (showOccurrenceWorkbench)
            PetEventOpenOccurrencesSection(entry: entry, muted: muted)
          else
            _ClosedOccurrenceSummary(history: history, muted: muted),
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
          PetEventPastOccurrencesSection(entryId: entry.id, muted: muted),
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

class _LifecycleActions extends StatelessWidget {
  const _LifecycleActions({
    required this.isClosed,
    required this.onClose,
    required this.onReopen,
  });

  final bool isClosed;
  final VoidCallback onClose;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Align(
      alignment: Alignment.centerLeft,
      child: isClosed
          ? OutlinedButton(
              key: const Key('pet_event_reopen_button'),
              onPressed: onReopen,
              child: Text(l.reopenEventAction),
            )
          : OutlinedButton(
              key: const Key('pet_event_close_button'),
              onPressed: onClose,
              child: Text(l.closeEventAction),
            ),
    );
  }
}

class _ClosedOccurrenceSummary extends StatelessWidget {
  const _ClosedOccurrenceSummary({
    required this.history,
    required this.muted,
  });

  final List<HealthHistoryEntry> history;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final last = sortedHistoryDesc(history).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.nextOccurrence,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: muted ? colorScheme.onSurfaceVariant : null,
          ),
        ),
        const SizedBox(height: 8),
        if (last == null)
          Text(
            l.noHistoryYet,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          _ClosedIterationCard(historyEntry: last),
      ],
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
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
