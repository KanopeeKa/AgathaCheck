import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_timeline_segment.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_timeline/pet_timeline_display_options.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_timeline/pet_timeline_list_builder.dart';

void main() {
  group('buildPetTimelineList', () {
    final pet = Pet(
      id: 'pet-1',
      name: 'Max',
      species: 'Dog',
      dateOfBirth: DateTime(2020, 1, 1),
      createdAt: DateTime(2024, 6, 1),
      primaryHolderName: 'Jane',
    );

    test('includes DOB and joined markers plus API segments', () {
      final list = buildPetTimelineList(
        pet: pet,
        apiSegments: const [
          PetTimelineSegment(
            kind: 'fostering_session',
            id: 'fp-1',
            startDate: '2025-06-01',
            fosterName: 'Frank',
          ),
          PetTimelineSegment(
            kind: 'manual',
            id: 'm-1',
            startDate: '2025-01-01',
            title: 'Note',
          ),
          PetTimelineSegment(
            kind: 'gap',
            id: 'gap-1',
            startDate: '2023-01-01',
            fillable: true,
          ),
          PetTimelineSegment(
            kind: 'custody',
            id: 'c-1',
            startDate: '2022-01-01',
            primaryHolderName: 'Bob',
          ),
        ],
      );

      expect(list.any((s) => s.isDateOfBirth), isTrue);
      expect(list.any((s) => s.isJoinedAgatha), isTrue);
      expect(list.where((s) => s.isFosteringSession), hasLength(1));
      expect(list.where((s) => s.isManual), hasLength(1));
      expect(list.any((s) => s.isGap), isFalse);
      expect(list.any((s) => s.isCustody), isFalse);
    });

    test('sorts entries latest first by start date', () {
      final list = buildPetTimelineList(
        pet: pet,
        apiSegments: const [
          PetTimelineSegment(
            kind: 'manual',
            id: 'old',
            startDate: '2023-01-01',
            title: 'Old',
          ),
          PetTimelineSegment(
            kind: 'manual',
            id: 'new',
            startDate: '2025-06-01',
            title: 'New',
          ),
        ],
      );

      expect(list.first.startDate, '2025-06-01');
      expect(list.last.startDate, '2020-01-01');
    });

    test('includes custody and gaps when display options enable them', () {
      final list = buildPetTimelineList(
        pet: null,
        apiSegments: const [
          PetTimelineSegment(
            kind: 'gap',
            id: 'gap-1',
            startDate: '2023-01-01',
            fillable: true,
          ),
          PetTimelineSegment(
            kind: 'custody',
            id: 'c-1',
            startDate: '2022-01-01',
            primaryHolderName: 'Bob',
          ),
        ],
        options: const PetTimelineDisplayOptions(
          includeCustody: true,
          includeGaps: true,
        ),
      );

      expect(list.where((s) => s.isGap), hasLength(1));
      expect(list.where((s) => s.isCustody), hasLength(1));
    });
  });
}
