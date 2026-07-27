import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/domain/entities/health_issue.dart';
import '../../../health_tracking/presentation/providers/health_issue_providers.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../pet_profile/presentation/controllers/health_issues_controller.dart';

class HealthIssueLinkedEventsStrip extends ConsumerWidget {
  const HealthIssueLinkedEventsStrip({
    super.key,
    required this.petId,
    required this.issue,
    required this.controller,
  });

  final String petId;
  final HealthIssue issue;
  final HealthIssuesController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(petHealthEntriesProvider(petId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              l.linkedEvents,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        entriesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(
            e.toString(),
            style: TextStyle(color: theme.colorScheme.error),
          ),
          data: (entries) {
            final linked = entries
                .where((e) => issue.eventIds.contains(e.id))
                .toList();
            return SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: linked.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index < linked.length) {
                    return _LinkedEventChip(
                      entry: linked[index],
                      onTap: () => context.push(
                        '/pet/$petId/health/edit/${linked[index].id}',
                      ),
                      onRemove: () => ref
                          .read(healthIssueNotifierProvider(petId).notifier)
                          .unlinkEvent(issue.id, linked[index].id),
                    );
                  }
                  return _AddLinkedEventChip(
                    onTap: () =>
                        controller.showLinkEventPicker(context, petId, issue),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LinkedEventChip extends StatelessWidget {
  const _LinkedEventChip({
    required this.entry,
    required this.onTap,
    required this.onRemove,
  });

  final HealthEntry entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      entry.type.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: AppLocalizations.of(context)!.unlink,
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddLinkedEventChip extends StatelessWidget {
  const _AddLinkedEventChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 18),
      label: Text(l.linkEvent),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 72),
        foregroundColor: colorScheme.primary,
      ),
    );
  }
}
