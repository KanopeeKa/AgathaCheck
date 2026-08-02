import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/pet_timeline_segment.dart';
import 'pet_timeline_entry_tile.dart';
import 'pet_timeline_event_row.dart';
import 'pet_timeline_year_divider.dart';

/// Vertical pet timeline: spine, nodes, subtle year dividers (newest first).
class PetTimelineView extends ConsumerWidget {
  const PetTimelineView({
    super.key,
    required this.segments,
    required this.petId,
    required this.petName,
  });

  final List<PetTimelineSegment> segments;
  final String petId;
  final String petName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = <Widget>[];
    String? lastYear;

    for (var index = 0; index < segments.length; index++) {
      final segment = segments[index];
      final year = _segmentYear(segment);
      if (year != lastYear) {
        children.add(PetTimelineYearDivider(year: year));
        lastYear = year;
      }

      final isLast = index == segments.length - 1;
      children.add(
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: PetTimelineEventRow(
            segment: segment,
            showConnectorBelow: !isLast,
            child: PetTimelineEntryTile(
              segment: segment,
              petId: petId,
              petName: petName,
            ),
          ),
        ),
      );
    }

    return ListView(
      key: const Key('pet_timeline_list'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: children,
    );
  }

  String _segmentYear(PetTimelineSegment segment) {
    final start = segment.startDate;
    if (start.length >= 4) return start.substring(0, 4);
    return start;
  }
}
