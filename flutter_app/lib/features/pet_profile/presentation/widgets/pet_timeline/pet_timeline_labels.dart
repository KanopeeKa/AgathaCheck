import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/pet_timeline_segment.dart';

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

String petTimelineHeadline(PetTimelineSegment segment, AppLocalizations l) {
  if (segment.isDateOfBirth) return l.dateOfBirth;
  if (segment.isJoinedAgatha) return petTimelineJoinedLabel(l);
  if (segment.isFosteringSession) {
    return l.petTimelineFosteringSession(
      segment.fosterName ?? l.petTimelineUnknownPerson,
    );
  }
  if (segment.isCustody) {
    final guardian = segment.primaryHolderName?.trim();
    if (guardian == null || guardian.isEmpty) {
      return l.petTimelineCustodySegmentHidden;
    }
    return l.petTimelineCustodySegment(guardian);
  }
  if (segment.isGap) return l.petTimelineNoData;
  return segment.title.isNotEmpty ? segment.title : l.petTimelineManualEntry;
}

String? petTimelineSubtitle(PetTimelineSegment segment, AppLocalizations l) {
  if (segment.isJoinedAgatha) {
    final guardian = segment.primaryHolderName?.trim();
    if (guardian == null || guardian.isEmpty) return null;
    return l.petTimelineCustodySegment(guardian);
  }
  if (segment.description.isNotEmpty) return segment.description;
  return null;
}

IconData petTimelineIcon(PetTimelineSegment segment) {
  if (segment.isDateOfBirth) return Icons.cake_outlined;
  if (segment.isJoinedAgatha) return Icons.pets_outlined;
  if (segment.isFosteringSession) return Icons.home_work_outlined;
  if (segment.isCustody) return Icons.swap_horiz_outlined;
  if (segment.isGap) return Icons.more_horiz;
  return Icons.edit_note_outlined;
}
