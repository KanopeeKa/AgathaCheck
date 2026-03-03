import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/health_entry.dart';

class HealthEntryCard extends StatelessWidget {
  const HealthEntryCard({
    super.key,
    required this.entry,
    this.pet,
    this.onMarkTaken,
    this.onSnooze,
    this.onTap,
    this.healthIssueName,
  });

  final HealthEntry entry;
  final Pet? pet;
  final VoidCallback? onMarkTaken;
  final void Function(int days)? onSnooze;
  final VoidCallback? onTap;
  final String? healthIssueName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusColor = entry.isCompleted
        ? Colors.green
        : entry.isOverdue
            ? colorScheme.error
            : entry.isDueToday
                ? Colors.orange
                : entry.isDueSoon
                    ? Colors.amber.shade700
                    : colorScheme.primary;

    final statusText = entry.isCompleted
        ? 'done'
        : entry.isOverdue
            ? 'overdue'
            : entry.isDueToday
                ? 'due today'
                : 'upcoming';

    final showActions = !entry.isCompleted;

    return MergeSemantics(
      child: Semantics(
        label: '${entry.name}, ${entry.type.label}, $statusText${pet != null ? ', for ${pet!.name}' : ''}',
        child: Card(
          elevation: 0.5,
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PetStrip(pet: pet, colorScheme: colorScheme),
                Expanded(
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              ExcludeSemantics(
                                child: Icon(_typeIcon(entry.type),
                                    color: colorScheme.primary, size: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    entry.dosage.isNotEmpty
                                        ? '${entry.name} · ${entry.dosage}'
                                        : entry.name,
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (entry.isCompleted) _DoneChip(entry: entry),
                            ],
                          ),
                          if (healthIssueName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(
                                children: [
                                  ExcludeSemantics(
                                    child: Icon(Icons.health_and_safety,
                                        size: 12, color: colorScheme.tertiary),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      healthIssueName!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.tertiary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              ExcludeSemantics(
                                child: Icon(Icons.schedule, size: 13, color: statusColor),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _formatDueDate(entry),
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: statusColor, fontWeight: FontWeight.w600, fontSize: 11),
                              ),
                              const Spacer(),
                              _FrequencyBadge(frequency: entry.frequency, interval: entry.frequencyInterval),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showActions) ...[
                  _SnoozeButton(
                    onSnooze: onSnooze,
                  ),
                  _MarkDoneButton(
                    onPressed: onMarkTaken,
                    petStripWidth: 52,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(HealthEntryType type) {
    switch (type) {
      case HealthEntryType.medication:
        return Icons.medication;
      case HealthEntryType.preventive:
        return Icons.shield;
      case HealthEntryType.vetVisit:
        return Icons.local_hospital;
      case HealthEntryType.procedure:
        return Icons.more_horiz;
    }
  }

  String _formatDueDate(HealthEntry entry) {
    if (entry.isCompleted) {
      return 'Done';
    }
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

class _MarkDoneButton extends StatelessWidget {
  const _MarkDoneButton({this.onPressed, required this.petStripWidth});

  final VoidCallback? onPressed;
  final double petStripWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: petStripWidth * 2,
      child: Material(
        color: Colors.green.shade50,
        child: InkWell(
          onTap: onPressed,
          splashColor: Colors.green.shade100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 22, color: Colors.green.shade700),
                const SizedBox(height: 4),
                Text(
                  'Mark Done',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SnoozeButton extends StatelessWidget {
  const _SnoozeButton({this.onSnooze});

  final void Function(int days)? onSnooze;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 48,
      child: Material(
        color: Colors.orange.shade50,
        child: InkWell(
          onTap: () => _showSnoozePicker(context),
          splashColor: Colors.orange.shade100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.snooze, size: 18, color: Colors.orange.shade700),
                const SizedBox(height: 2),
                Text(
                  'Snooze',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnoozePicker(BuildContext context) {
    int selectedDays = 1;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.snooze, color: Colors.orange.shade700, size: 22),
                  const SizedBox(width: 8),
                  const Text('Snooze Event'),
                ],
              ),
              content: SizedBox(
                height: 160,
                child: Column(
                  children: [
                    Text(
                      'Postpone for how many days?',
                      style: Theme.of(ctx).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 40,
                        diameterRatio: 1.5,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setDialogState(() => selectedDays = index + 1);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 90,
                          builder: (context, index) {
                            final day = index + 1;
                            final isSelected = day == selectedDays;
                            return Center(
                              child: Text(
                                day == 1 ? '1 day' : '$day days',
                                style: TextStyle(
                                  fontSize: isSelected ? 20 : 15,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.orange.shade800
                                      : Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onSnooze?.call(selectedDays);
                  },
                  child: Text('Snooze $selectedDays ${selectedDays == 1 ? 'day' : 'days'}'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PetStrip extends StatelessWidget {
  const _PetStrip({this.pet, required this.colorScheme});

  final Pet? pet;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final petColor = pet?.colorValue != null
        ? Color(pet!.colorValue!)
        : colorScheme.surfaceContainerHighest;

    return Container(
      width: 52,
      decoration: BoxDecoration(
        color: petColor.withOpacity(0.18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAvatar(petColor),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              pet?.name ?? '?',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Color petColor) {
    if (pet?.photoPath != null && pet!.photoPath!.isNotEmpty) {
      try {
        final bytes = base64Decode(pet!.photoPath!);
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: petColor, width: 2),
          ),
          child: ClipOval(
            child: Image.memory(bytes, width: 26, height: 26, fit: BoxFit.cover),
          ),
        );
      } catch (_) {}
    }
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: petColor.withOpacity(0.25),
        border: Border.all(color: petColor, width: 2),
      ),
      child: Icon(Icons.pets, size: 14, color: petColor),
    );
  }
}

class _DoneChip extends StatelessWidget {
  const _DoneChip({required this.entry});

  final HealthEntry entry;

  @override
  Widget build(BuildContext context) {
    final doneDate = entry.updatedAt ?? entry.startDate;
    final dateStr = DateFormat('d MMM').format(doneDate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
          const SizedBox(width: 3),
          Text(
            'Done $dateStr',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrequencyBadge extends StatelessWidget {
  const _FrequencyBadge({required this.frequency, this.interval = 1});

  final HealthFrequency frequency;
  final int interval;

  String get _displayLabel {
    if (frequency == HealthFrequency.once) return 'Does not repeat';
    if (frequency == HealthFrequency.custom) return 'Custom';
    final period = frequency.label;
    if (interval == 1) return 'Every $period';
    return 'Every $interval ${period}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _displayLabel,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
