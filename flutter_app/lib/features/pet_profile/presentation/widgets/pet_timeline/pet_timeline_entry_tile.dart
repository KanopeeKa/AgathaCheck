import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/pet_timeline_segment.dart';
import '../../providers/pet_timeline_providers.dart';
import 'pet_timeline_fill_sheet.dart';

String petTimelineDateRangeLabel(
  PetTimelineSegment segment,
  AppLocalizations l,
) {
  final end = segment.endDate;
  if (end == null || end.isEmpty || end == segment.startDate) {
    return segment.startDate;
  }
  return l.petTimelineDateRange(segment.startDate, end);
}

String petTimelineJoinedLabel(AppLocalizations l) =>
    l.petTimelineJoinedAgatha(l.appTitle);

class PetTimelineEntryTile extends ConsumerWidget {
  const PetTimelineEntryTile({
    super.key,
    required this.segment,
    required this.petId,
    required this.petName,
  });

  final PetTimelineSegment segment;
  final String petId;
  final String petName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final headline = _headline(segment, l);
    final subtitle = _subtitle(segment, l);
    final icon = _icon(segment);

    return Card(
      key: Key('timeline_entry_${segment.kind}_${segment.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(headline),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(petTimelineDateRangeLabel(segment, l)),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(subtitle),
              ),
          ],
        ),
        isThreeLine: subtitle != null,
        trailing: segment.isManual
            ? _ManualActions(segment: segment, petId: petId, petName: petName)
            : null,
      ),
    );
  }

  String _headline(PetTimelineSegment segment, AppLocalizations l) {
    if (segment.isDateOfBirth) return l.dateOfBirth;
    if (segment.isJoinedAgatha) return petTimelineJoinedLabel(l);
    if (segment.isFosteringSession) {
      return l.petTimelineFosteringSession(
        segment.fosterName ?? l.petTimelineUnknownPerson,
      );
    }
    return segment.title.isNotEmpty ? segment.title : l.petTimelineManualEntry;
  }

  String? _subtitle(PetTimelineSegment segment, AppLocalizations l) {
    if (segment.isJoinedAgatha) {
      final guardian = segment.guardianName?.trim();
      if (guardian == null || guardian.isEmpty) return null;
      return l.petTimelineCustodySegment(guardian);
    }
    if (segment.description.isNotEmpty) return segment.description;
    return null;
  }

  IconData _icon(PetTimelineSegment segment) {
    if (segment.isDateOfBirth) return Icons.cake_outlined;
    if (segment.isJoinedAgatha) return Icons.pets_outlined;
    if (segment.isFosteringSession) return Icons.home_work_outlined;
    return Icons.edit_note_outlined;
  }
}

class _ManualActions extends ConsumerWidget {
  const _ManualActions({
    required this.segment,
    required this.petId,
    required this.petName,
  });

  final PetTimelineSegment segment;
  final String petId;
  final String petName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: Key('timeline_edit_${segment.id}'),
          icon: const Icon(Icons.edit_outlined),
          tooltip: l.edit,
          onPressed: () => showPetTimelineFillSheet(
            context,
            ref,
            petId: petId,
            petName: petName,
            existingEntry: segment,
          ),
        ),
        IconButton(
          key: Key('timeline_delete_${segment.id}'),
          icon: const Icon(Icons.delete_outline),
          tooltip: l.delete,
          onPressed: () => _confirmDelete(context, ref, l),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteEntry),
        content: Text(l.deleteTimelineEntryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await deletePetTimelineManualEntry(ref, petId, segment.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.petTimelineFillError)));
      }
    }
  }
}
