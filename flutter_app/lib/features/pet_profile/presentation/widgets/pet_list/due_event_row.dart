import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/widgets/due_event_card.dart';
import '../../../domain/entities/pet.dart';

/// Single due/overdue event row wrapping [DueEventCard].
class DueEventRow extends ConsumerWidget {
  const DueEventRow({
    super.key,
    required this.entry,
    required this.pet,
    required this.showInlineActions,
  });

  final HealthEntry entry;
  final Pet? pet;
  final bool showInlineActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DueEventCard(
        entry: entry,
        pet: pet,
        showActions: showInlineActions,
      ),
    );
  }
<<<<<<< HEAD

  IconData _entryTypeIcon(HealthEntryType type) {
    switch (type) {
      case HealthEntryType.medication:
        return Icons.medication;
      case HealthEntryType.preventive:
        return Icons.shield;
      case HealthEntryType.vetVisit:
        return Icons.local_hospital;
      case HealthEntryType.other:
        return Icons.more_horiz;
    }
  }
=======
>>>>>>> b3f7980c (phase(6/15): feat: unified DueEventCard on dashboard and pet profile)
}
