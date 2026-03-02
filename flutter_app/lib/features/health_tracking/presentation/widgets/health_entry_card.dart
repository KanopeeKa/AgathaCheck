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
    this.onTap,
  });

  final HealthEntry entry;
  final Pet? pet;
  final VoidCallback? onMarkTaken;
  final VoidCallback? onTap;

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

    return MergeSemantics(
      child: Semantics(
        label: '${entry.name}, ${entry.type.label}, $statusText${pet != null ? ', for ${pet!.name}' : ''}',
        child: Card(
          elevation: 0.5,
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PetStrip(pet: pet, colorScheme: colorScheme),
                  Expanded(
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
                                child: Text(entry.name,
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (entry.isCompleted)
                                _DoneChip(entry: entry)
                              else
                                SizedBox(
                                  height: 28,
                                  child: FilledButton.tonal(
                                    onPressed: onMarkTaken,
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      textStyle: const TextStyle(fontSize: 11),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    child: const Text('Mark Taken'),
                                  ),
                                ),
                            ],
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
                              _FrequencyBadge(frequency: entry.frequency),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
  const _FrequencyBadge({required this.frequency});

  final HealthFrequency frequency;

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
        frequency.label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
