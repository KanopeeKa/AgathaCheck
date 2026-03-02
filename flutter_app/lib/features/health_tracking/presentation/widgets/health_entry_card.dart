import 'package:flutter/material.dart';

import '../../domain/entities/health_entry.dart';

/// Displays a single health entry as a Material 3 card.
///
/// Shows the entry name, next due date, frequency badge,
/// and a button to mark it as taken.
class HealthEntryCard extends StatelessWidget {
  /// Creates a [HealthEntryCard] for the given [entry].
  const HealthEntryCard({
    super.key,
    required this.entry,
    this.onMarkTaken,
    this.onTap,
    this.onDelete,
  });

  /// The health entry to display.
  final HealthEntry entry;

  /// Called when the user taps the 'Mark Taken' button.
  final VoidCallback? onMarkTaken;

  /// Called when the user taps the card.
  final VoidCallback? onTap;

  /// Called when the user confirms deletion.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusColor = entry.isOverdue
        ? colorScheme.error
        : entry.isDueToday
            ? Colors.orange
            : entry.isDueSoon
                ? Colors.amber.shade700
                : colorScheme.primary;

    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_typeIcon(entry.type),
                      color: colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.name,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        if (entry.dosage.isNotEmpty)
                          Text(entry.dosage,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: colorScheme.outline)),
                      ],
                    ),
                  ),
                  _FrequencyBadge(frequency: entry.frequency),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    _formatDueDate(entry),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 20, color: colorScheme.error),
                      onPressed: () => _confirmDelete(context),
                      tooltip: 'Delete',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  const SizedBox(width: 4),
                  FilledButton.tonal(
                    onPressed: onMarkTaken,
                    child: const Text('Mark Taken'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Delete "${entry.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(HealthEntryType type) {
    switch (type) {
      case HealthEntryType.medication:
        return Icons.medication;
      case HealthEntryType.preventive:
        return Icons.shield;
      case HealthEntryType.vaccine:
        return Icons.vaccines;
      case HealthEntryType.procedure:
        return Icons.local_hospital;
    }
  }

  String _formatDueDate(HealthEntry entry) {
    if (entry.isOverdue) {
      return 'Overdue';
    }
    if (entry.isDueToday) {
      final hour = entry.nextDueDate.hour;
      final minute = entry.nextDueDate.minute;
      return 'Due today at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
    final diff = entry.nextDueDate.difference(DateTime.now());
    if (diff.inDays == 0) {
      return 'Due in ${diff.inHours}h';
    }
    if (diff.inDays == 1) {
      return 'Due tomorrow';
    }
    return 'Due in ${diff.inDays} days';
  }
}

class _FrequencyBadge extends StatelessWidget {
  const _FrequencyBadge({required this.frequency});

  final HealthFrequency frequency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        frequency.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
