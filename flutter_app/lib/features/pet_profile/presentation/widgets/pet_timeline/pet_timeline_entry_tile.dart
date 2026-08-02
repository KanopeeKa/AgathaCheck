import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/pet_timeline_segment.dart';
import '../../providers/pet_timeline_providers.dart';
import 'pet_timeline_fill_sheet.dart';
import 'pet_timeline_labels.dart';

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

    final headline = petTimelineHeadline(segment, l);
    final subtitle = petTimelineSubtitle(segment, l);

    return Card(
      key: Key('timeline_entry_${segment.kind}_${segment.id}'),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
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
          ),
          if (segment.isManual)
            _ManualActions(segment: segment, petId: petId, petName: petName),
          if (segment.isGap && segment.fillable)
            _GapFillAction(segment: segment, petId: petId, petName: petName),
        ],
      ),
    );
  }
}

class _GapFillAction extends ConsumerWidget {
  const _GapFillAction({
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: FilledButton.icon(
        key: Key('timeline_fill_${segment.id}'),
        onPressed: () => showPetTimelineFillSheet(
          context,
          ref,
          petId: petId,
          petName: petName,
          initialStartDate: segment.startDate,
          initialEndDate: segment.endDate,
        ),
        icon: const Icon(Icons.edit_note_outlined),
        label: Text(l.petTimelineFillAction),
      ),
    );
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: Key('timeline_edit_${segment.id}'),
              onPressed: () => showPetTimelineFillSheet(
                context,
                ref,
                petId: petId,
                petName: petName,
                existingEntry: segment,
              ),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l.edit),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              key: Key('timeline_delete_${segment.id}'),
              onPressed: () => _confirmDelete(context, ref, l),
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              label: Text(l.delete, style: TextStyle(color: colorScheme.error)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.error),
              ),
            ),
          ),
        ],
      ),
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
