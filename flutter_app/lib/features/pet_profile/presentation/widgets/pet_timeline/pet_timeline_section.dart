import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/dashboard_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/pet_timeline_segment.dart';
import '../../providers/pet_timeline_providers.dart';
import 'pet_timeline_fill_sheet.dart';

/// Pet detail timeline: custody segments, fostering sessions, manual entries, gaps.
class PetTimelineSection extends ConsumerWidget {
  const PetTimelineSection({
    super.key,
    required this.petId,
    required this.petName,
  });

  final String petId;
  final String petName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final timelineAsync = ref.watch(petTimelineProvider(petId));

    return Padding(
      key: const Key('pet_timeline_section'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DashboardSection(
        title: l.petTimelineTitle,
        previewBuilder: (ctx) {
          return timelineAsync.when(
            loading: () => const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text(
              l.petTimelineLoadError,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            data: (segments) {
              if (segments.isEmpty) {
                return Text(l.petTimelineNoData);
              }
              return Column(
                children: segments
                    .map(
                      (segment) => _TimelineSegmentTile(
                        segment: segment,
                        petId: petId,
                        petName: petName,
                      ),
                    )
                    .toList(),
              );
            },
          );
        },
      ),
    );
  }
}

class _TimelineSegmentTile extends ConsumerWidget {
  const _TimelineSegmentTile({
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

    if (segment.isGap) {
      return Card(
        key: Key('timeline_gap_${segment.id}'),
        margin: const EdgeInsets.only(bottom: 8),
        color: theme.colorScheme.surfaceContainerHighest,
        child: ListTile(
          title: Text(l.petTimelineNoData),
          subtitle: Text(_dateRangeLabel(segment, l)),
          trailing: FilledButton.tonal(
            key: Key('timeline_fill_${segment.id}'),
            onPressed: () => showPetTimelineFillSheet(
              context,
              ref,
              petId: petId,
              petName: petName,
              initialStartDate: segment.startDate,
              initialEndDate: segment.endDate,
            ),
            child: Text(l.petTimelineFillAction),
          ),
        ),
      );
    }

    final headline = segment.isFosteringSession
        ? l.petTimelineFosteringSession(
            segment.fosterName ?? l.petTimelineUnknownPerson,
          )
        : segment.isCustody
        ? (segment.guardianName != null
              ? l.petTimelineCustodySegment(segment.guardianName!)
              : l.petTimelineCustodySegmentHidden)
        : (segment.title.isNotEmpty ? segment.title : l.petTimelineManualEntry);

    return Card(
      key: Key('timeline_segment_${segment.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          segment.isFosteringSession
              ? Icons.home_work_outlined
              : segment.isCustody
              ? Icons.swap_horiz
              : Icons.edit_note_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(headline),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_dateRangeLabel(segment, l)),
            if (segment.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(segment.description),
              ),
          ],
        ),
        isThreeLine: segment.description.isNotEmpty,
      ),
    );
  }

  String _dateRangeLabel(PetTimelineSegment segment, AppLocalizations l) {
    final end = segment.endDate;
    if (end == null || end.isEmpty || end == segment.startDate) {
      return segment.startDate;
    }
    return l.petTimelineDateRange(segment.startDate, end);
  }
}
