import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_timeline_segment.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_timeline/pet_timeline_labels.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  group('petTimeline labels for care milestones', () {
    late AppLocalizations l;

    setUpAll(() async {
      l = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('headline uses milestone title', () {
      const segment = PetTimelineSegment(
        kind: 'care_milestone',
        id: 'ms-1',
        startDate: '2025-09-01',
        milestoneType: 'weight_monitoring_established',
      );

      expect(petTimelineHeadline(segment, l), l.careProgressionMilestoneTitle);
    });

    test('subtitle uses combined copy when first care milestone bundled', () {
      const segment = PetTimelineSegment(
        kind: 'care_milestone',
        id: 'ms-1',
        startDate: '2025-09-01',
        milestoneType: 'weight_monitoring_established',
        includesFirstCare: true,
      );

      final subtitle = petTimelineSubtitle(segment, l, petName: 'Max');
      expect(subtitle, l.careProgressionFirstCareCombinedBody('Max'));
    });

    test('subtitle uses weight established copy for standalone milestone', () {
      const segment = PetTimelineSegment(
        kind: 'care_milestone',
        id: 'ms-1',
        startDate: '2025-09-01',
        milestoneType: 'weight_monitoring_established',
      );

      final subtitle = petTimelineSubtitle(segment, l, petName: 'Max');
      expect(subtitle, l.careProgressionWeightEstablishedBody('Max'));
    });

    test('icon is milestone-specific', () {
      const segment = PetTimelineSegment(
        kind: 'care_milestone',
        id: 'ms-1',
        startDate: '2025-09-01',
      );

      expect(petTimelineIcon(segment).codePoint, isNotNull);
    });
  });
}
