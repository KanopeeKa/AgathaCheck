import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/controllers/pet_list_controller.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_dashboard_helpers.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final controller = PetListController();

  test('guardianDashboardPersonalPets returns owned pets only, sorted', () {
    final pets = [
      Pet(
        id: '2',
        name: 'Beta',
        species: 'Dog',
        breed: '',
        createdAt: DateTime(2024, 2, 1),
      ),
      Pet(
        id: '1',
        name: 'Alpha',
        species: 'Dog',
        breed: '',
        createdAt: DateTime(2024, 1, 1),
      ),
      Pet(
        id: '3',
        name: 'Foster',
        species: 'Cat',
        breed: '',
        isFoster: true,
        createdAt: DateTime(2024, 3, 1),
      ),
      Pet(
        id: '4',
        name: 'Shared',
        species: 'Dog',
        breed: '',
        isShared: true,
        createdAt: DateTime(2024, 4, 1),
      ),
    ];

    final personal = guardianDashboardPersonalPets(pets, controller);
    expect(personal.length, 2);
    expect(personal.map((p) => p.name).toList(), ['Alpha', 'Beta']);
  });

  test('guardianDashboardPersonalPets excludes shared and foster pets', () {
    final pets = [
      const Pet(id: '1', name: 'Mine', species: 'Dog', breed: ''),
      const Pet(
        id: '2',
        name: 'Shared',
        species: 'Cat',
        breed: '',
        isShared: true,
      ),
      const Pet(
        id: '3',
        name: 'Fostered',
        species: 'Cat',
        breed: '',
        isFoster: true,
      ),
    ];

    final personal = guardianDashboardPersonalPets(pets, controller);
    expect(personal.map((p) => p.name).toList(), ['Mine']);
  });

  test('guardianDashboardSharedPets returns shared pets only', () {
    final pets = [
      const Pet(id: '1', name: 'Mine', species: 'Dog', breed: ''),
      const Pet(
        id: '2',
        name: 'Shared',
        species: 'Cat',
        breed: '',
        isShared: true,
      ),
      const Pet(
        id: '3',
        name: 'Fostered',
        species: 'Cat',
        breed: '',
        isFoster: true,
      ),
    ];

    final shared = guardianDashboardSharedPets(pets, controller);
    expect(shared.map((p) => p.name).toList(), ['Shared']);
  });

  test('guardianDashboardFosterPets returns foster pets only', () {
    final pets = [
      const Pet(id: '1', name: 'Mine', species: 'Dog', breed: ''),
      const Pet(
        id: '2',
        name: 'Fostered',
        species: 'Cat',
        breed: '',
        isFoster: true,
      ),
    ];

    final fostered = guardianDashboardFosterPets(pets, controller);
    expect(fostered.length, 1);
    expect(fostered.first.name, 'Fostered');
  });

  test('passed-away pets are excluded from dashboard groups', () {
    final pets = [
      const Pet(
        id: '1',
        name: 'Alive',
        species: 'Dog',
        breed: '',
        passedAway: false,
      ),
      const Pet(
        id: '2',
        name: 'Gone',
        species: 'Dog',
        breed: '',
        passedAway: true,
      ),
    ];

    expect(guardianDashboardPersonalPets(pets, controller).length, 1);
    expect(guardianDashboardHasAnyPets(pets, controller), isTrue);
  });

  test(
    'Rail pets are attention-first and preview metadata keeps legacy cap',
    () {
      final now = DateTime.now();
      final pets = List.generate(
        6,
        (index) => Pet(
          id: 'pet-$index',
          name: 'Pet $index',
          species: 'Dog',
          breed: '',
          createdAt: now.add(Duration(days: index)),
        ),
      );
      final entries = [
        HealthEntry(
          id: 'due-today',
          petId: 'pet-4',
          name: 'Today',
          type: HealthEntryType.other,
          frequency: HealthFrequency.daily,
          startDate: now,
          nextDueDate: now,
        ),
        HealthEntry(
          id: 'overdue',
          petId: 'pet-5',
          name: 'Overdue',
          type: HealthEntryType.other,
          frequency: HealthFrequency.daily,
          startDate: now.subtract(const Duration(days: 2)),
          nextDueDate: now.subtract(const Duration(days: 1)),
        ),
      ];

      final summary = GuardianTodayCareSummary.forPets(
        entries: entries,
        pets: pets,
        now: now,
      );
      final rail = guardianTodayRailPets(pets, controller, summary);
      final preview = guardianTodayPetPreview(pets, controller, summary);

      expect(rail, hasLength(6));
      expect(rail.take(2).map((pet) => pet.id), ['pet-5', 'pet-4']);
      expect(preview.visiblePets, hasLength(4));
      expect(preview.overflowCount, 2);
      expect(pets.map((pet) => pet.id), [
        'pet-0',
        'pet-1',
        'pet-2',
        'pet-3',
        'pet-4',
        'pet-5',
      ]);
      expect(entries.map((entry) => entry.id), ['due-today', 'overdue']);
    },
  );

  test('care priorities classify and order with an injected date', () {
    final now = DateTime(2030, 5, 10, 14);
    final pet = const Pet(id: 'p1', name: 'Miso', species: 'Dog');
    final entries = [
      _entry('upcoming-later', pet.id, DateTime(2030, 5, 12)),
      _entry('today', pet.id, DateTime(2030, 5, 10)),
      _entry('overdue-earlier', pet.id, DateTime(2030, 5, 7)),
      _entry('overdue-later', pet.id, DateTime(2030, 5, 9)),
      _entry('upcoming-soon', pet.id, DateTime(2030, 5, 11)),
      _entry('outside-window', pet.id, DateTime(2030, 5, 20)),
    ];

    final priorities = GuardianTodayCarePriorities.forPets(
      entries: entries,
      pets: [pet],
      now: now,
    );

    expect(priorities.overdue.map((entry) => entry.id), [
      'overdue-earlier',
      'overdue-later',
    ]);
    expect(priorities.dueToday.single.id, 'today');
    expect(priorities.upcoming.map((entry) => entry.id), [
      'upcoming-soon',
      'upcoming-later',
    ]);
    expect(priorities.preview, hasLength(5));
    expect(entries.last.id, 'outside-window');
  });

  test(
    'preview metadata, relationship and screen states are deterministic',
    () {
      final pets = List.generate(
        5,
        (index) => Pet(id: '$index', name: 'Pet $index', species: 'Dog'),
      );
      final summary = GuardianTodayCareSummary.forPets(
        entries: const [],
        pets: pets,
        now: DateTime(2030, 1, 1),
      );
      final preview = guardianTodayPetPreview(pets, controller, summary);

      expect(preview.visiblePets, hasLength(4));
      expect(preview.overflowCount, 1);
      expect(preview.hasOverflow, isTrue);
      expect(
        guardianTodayPetRelationship(
          const Pet(
            id: 'shared',
            name: 'Shared',
            species: 'Cat',
            isShared: true,
          ),
        ),
        GuardianTodayPetRelationship.shared,
      );
      expect(
        guardianTodayPetRelationship(
          const Pet(
            id: 'fostered',
            name: 'Fostered',
            species: 'Cat',
            isFoster: true,
          ),
        ),
        GuardianTodayPetRelationship.fostered,
      );
      expect(
        guardianTodayPetRelationship(
          const Pet(id: 'owned', name: 'Owned', species: 'Cat'),
        ),
        GuardianTodayPetRelationship.owned,
      );
      expect(
        guardianTodayScreenState(
          hasPets: false,
          hasCareData: false,
          isLoading: false,
          hasError: false,
          hasAttention: false,
        ),
        GuardianTodayScreenState.firstUse,
      );
      expect(
        guardianTodayScreenState(
          hasPets: true,
          hasCareData: true,
          isLoading: false,
          hasError: false,
          hasAttention: true,
        ),
        GuardianTodayScreenState.attention,
      );
      expect(
        guardianTodayScreenState(
          hasPets: true,
          hasCareData: true,
          isLoading: false,
          hasError: false,
          hasAttention: false,
        ),
        GuardianTodayScreenState.allClear,
      );
      expect(
        guardianTodayScreenState(
          hasPets: true,
          hasCareData: false,
          isLoading: true,
          hasError: false,
          hasAttention: false,
        ),
        GuardianTodayScreenState.loading,
      );
      expect(
        guardianTodayScreenState(
          hasPets: true,
          hasCareData: false,
          isLoading: false,
          hasError: false,
          hasAttention: false,
        ),
        GuardianTodayScreenState.partial,
      );
      expect(
        guardianTodayScreenState(
          hasPets: true,
          hasCareData: true,
          isLoading: false,
          hasError: true,
          hasAttention: true,
        ),
        GuardianTodayScreenState.error,
      );
    },
  );
}

HealthEntry _entry(String id, String petId, DateTime dueDate) => HealthEntry(
  id: id,
  petId: petId,
  name: id,
  type: HealthEntryType.other,
  frequency: HealthFrequency.daily,
  startDate: dueDate.subtract(const Duration(days: 1)),
  nextDueDate: dueDate,
  remindDaysBefore: 2,
);
