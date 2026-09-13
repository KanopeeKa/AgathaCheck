import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/domain/entities/care_status.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/widgets/pet_card.dart'
    show sortPetsByCreatedAt;
import '../../../../pet_profile/presentation/widgets/pet_tile_status_line.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../pet_care/domain/care_temporal_group.dart';
import '../../../../pet_care/domain/services/care_temporal_grouping_service.dart';

/// Relationship wording is intentionally a presentation concern. Eligibility
/// remains owned by [PetListController].
enum PetCareTodayPetRelationship { owned, fostered, shared }

/// Care urgency in the Guardian Today presentation.
enum PetCareTodayCareUrgency { overdue, dueToday, upcoming }

/// Truthful data state for a consumer of the dashboard presentation model.
enum PetCareTodayScreenState {
  firstUse,
  allClear,
  attention,
  loading,
  partial,
  error,
}

/// Stable, grouped care values for the Guardian dashboard.
class PetCareTodayCarePriorities {
  const PetCareTodayCarePriorities._({
    required this.overdue,
    required this.dueToday,
    required this.upcoming,
  });

  static const previewLimit = 5;

  final List<HealthEntry> overdue;
  final List<HealthEntry> dueToday;
  final List<HealthEntry> upcoming;

  /// All visible care items, ordered by their due date regardless of urgency.
  List<HealthEntry> get all {
    final combined = [...overdue, ...dueToday, ...upcoming]
      ..sort((a, b) {
        final aDate = a.nextDueDate ?? DateTime(9999);
        final bDate = b.nextDueDate ?? DateTime(9999);
        return aDate.compareTo(bDate);
      });
    return List<HealthEntry>.unmodifiable(combined);
  }

  List<HealthEntry> get preview =>
      List<HealthEntry>.unmodifiable(all.take(previewLimit));

  int get attentionCount => overdue.length + dueToday.length;

  static PetCareTodayCarePriorities forPets({
    required List<HealthEntry> entries,
    required List<Pet> pets,
    required DateTime now,
    CareTemporalGroupingService grouping = const CareTemporalGroupingService(),
  }) {
    final petIds = pets
        .where((pet) => !pet.passedAway)
        .map((pet) => pet.id)
        .toSet();
    final buckets = grouping.bucketsForEntries(
      entries,
      petIds: petIds,
      now: now,
    );

    return PetCareTodayCarePriorities._(
      overdue: buckets.needsAttention,
      dueToday: buckets.today,
      upcoming: buckets.upcoming,
    );
  }
}

/// Capped pet values consumed by dashboard-only components.
class PetCareTodayPetPreview {
  const PetCareTodayPetPreview._({
    required this.visiblePets,
    required this.overflowCount,
  });

  static const visibleLimit = 4;

  final List<Pet> visiblePets;
  final int overflowCount;

  bool get hasOverflow => overflowCount > 0;
}

/// Pure, dashboard-only view of due care. It reuses the authoritative care
/// filter and never alters provider-owned lists.
class PetCareTodayCareSummary {
  const PetCareTodayCareSummary._({required this.priorities});

  final PetCareTodayCarePriorities priorities;

  List<HealthEntry> get dueEntries => priorities.all;
  int get overdueCount => priorities.overdue.length;
  int get dueTodayCount => priorities.dueToday.length;
  int get upcomingCount => priorities.upcoming.length;

  int get attentionCount => priorities.attentionCount;
  bool get hasAttention => attentionCount > 0;

  static PetCareTodayCareSummary forPets({
    required List<HealthEntry> entries,
    required List<Pet> pets,
    DateTime? now,
  }) {
    final priorities = PetCareTodayCarePriorities.forPets(
      entries: entries,
      pets: pets,
      now: now ?? DateTime.now(),
    );
    return PetCareTodayCareSummary._(priorities: priorities);
  }
}

/// Maps the canonical temporal group to dashboard urgency vocabulary.
PetCareTodayCareUrgency? petCareTodayCareUrgency(
  HealthEntry entry,
  DateTime now, {
  CareTemporalGroupingService grouping = const CareTemporalGroupingService(),
}) {
  final group = grouping.groupForEntry(entry, now);
  return switch (group) {
    CareTemporalGroup.needsAttention => PetCareTodayCareUrgency.overdue,
    CareTemporalGroup.today => PetCareTodayCareUrgency.dueToday,
    CareTemporalGroup.upcoming => PetCareTodayCareUrgency.upcoming,
    null => null,
  };
}

PetCareTodayPetRelationship petCareTodayPetRelationship(Pet pet) {
  if (pet.isShared) return PetCareTodayPetRelationship.shared;
  if (pet.isFoster) return PetCareTodayPetRelationship.fostered;
  return PetCareTodayPetRelationship.owned;
}

PetCareTodayScreenState petCareTodayScreenState({
  required bool hasPets,
  required bool hasCareData,
  required bool isLoading,
  required bool hasError,
  required bool hasAttention,
}) {
  if (hasError) return PetCareTodayScreenState.error;
  if (isLoading && !hasCareData) return PetCareTodayScreenState.loading;
  if (!hasPets) return PetCareTodayScreenState.firstUse;
  if (!hasCareData) return PetCareTodayScreenState.partial;
  return hasAttention
      ? PetCareTodayScreenState.attention
      : PetCareTodayScreenState.allClear;
}

/// Selects all active shell pets for the dashboard rail, attention-first when
/// [careSummary] is available.
List<Pet> petCareTodayRailPets(
  List<Pet> allPets,
  PetListController controller,
  PetCareTodayCareSummary? careSummary,
) {
  return _petCareDashboardShellPetsSorted(allPets, controller, careSummary);
}

/// Selects a stable, attention-first dashboard preview without changing any
/// ownership or visibility decisions made by [PetListController].
List<Pet> guardianTodayPreviewPets(
  List<Pet> allPets,
  PetListController controller,
  PetCareTodayCareSummary careSummary,
) {
  return petCareTodayRailPets(allPets, controller, careSummary);
}

List<Pet> _petCareDashboardShellPetsSorted(
  List<Pet> allPets,
  PetListController controller,
  PetCareTodayCareSummary? careSummary,
) {
  final shellPets = controller
      .guardianShellPets(allPets)
      .where((pet) => !pet.passedAway)
      .toList(growable: false);

  if (careSummary == null) {
    sortPetsByCreatedAt(shellPets);
    return List<Pet>.unmodifiable(shellPets);
  }

  final priorityByPetId = <String, int>{};
  for (final entry in careSummary.dueEntries) {
    final priority = switch (_urgencyForEntry(entry, careSummary)) {
      PetCareTodayCareUrgency.overdue => 0,
      PetCareTodayCareUrgency.dueToday => 1,
      PetCareTodayCareUrgency.upcoming => 2,
      null => 3,
    };
    final current = priorityByPetId[entry.petId];
    if (current == null || priority < current) {
      priorityByPetId[entry.petId] = priority;
    }
  }

  final indexed = shellPets.indexed.toList()
    ..sort((a, b) {
      final aPriority = priorityByPetId[a.$2.id] ?? 3;
      final bPriority = priorityByPetId[b.$2.id] ?? 3;
      final priorityOrder = aPriority.compareTo(bPriority);
      return priorityOrder != 0 ? priorityOrder : a.$1.compareTo(b.$1);
    });

  return List<Pet>.unmodifiable(indexed.map((item) => item.$2));
}

PetCareTodayPetPreview petCareTodayPetPreview(
  List<Pet> allPets,
  PetListController controller,
  PetCareTodayCareSummary careSummary,
) {
  final sorted = _petCareDashboardShellPetsSorted(
    allPets,
    controller,
    careSummary,
  );
  final visible = sorted.take(PetCareTodayPetPreview.visibleLimit).toList();
  return PetCareTodayPetPreview._(
    visiblePets: List<Pet>.unmodifiable(visible),
    overflowCount: (sorted.length - PetCareTodayPetPreview.visibleLimit)
        .clamp(0, sorted.length)
        .toInt(),
  );
}

/// Returns the Care Status for a pet in the dashboard preview.
CareStatus petCareStatusFor(
  Pet pet,
  PetCareTodayCareSummary careSummary, {
  CareTemporalGroupingService grouping = const CareTemporalGroupingService(),
}) {
  final priorities = careSummary.priorities;
  return grouping.careStatusFromFlags(
    hasNeedsAttention: priorities.overdue.any((entry) => entry.petId == pet.id),
    hasToday: priorities.dueToday.any((entry) => entry.petId == pet.id),
    hasUpcoming: priorities.upcoming.any((entry) => entry.petId == pet.id),
  );
}

@Deprecated('Use petCareStatusFor')
PetCareTodayPetCareState petCareTodayPetCareState(
  Pet pet,
  PetCareTodayCareSummary careSummary,
) {
  return switch (petCareStatusFor(pet, careSummary)) {
    CareStatus.timeToFollowUp => PetCareTodayPetCareState.overdue,
    CareStatus.worthACheck => PetCareTodayPetCareState.upcoming,
    CareStatus.allSet => PetCareTodayPetCareState.clear,
  };
}

enum PetCareTodayPetCareState { overdue, dueToday, upcoming, clear }

PetCareTodayCareUrgency? _urgencyForEntry(
  HealthEntry entry,
  PetCareTodayCareSummary summary,
) {
  if (summary.priorities.overdue.contains(entry)) {
    return PetCareTodayCareUrgency.overdue;
  }
  if (summary.priorities.dueToday.contains(entry)) {
    return PetCareTodayCareUrgency.dueToday;
  }
  if (summary.priorities.upcoming.contains(entry)) {
    return PetCareTodayCareUrgency.upcoming;
  }
  return null;
}

/// Active personal pets (owned and foster; not shared) for the guardian dashboard.
List<Pet> petCareDashboardPersonalPets(
  List<Pet> allPets,
  PetListController controller,
) {
  final shellPets = controller.guardianShellPets(allPets);
  final owned = controller.getOwnedPets(shellPets);
  sortPetsByCreatedAt(owned);
  return owned;
}

/// Active foster pets for the guardian dashboard, oldest first.
List<Pet> petCareDashboardFosterPets(
  List<Pet> allPets,
  PetListController controller,
) {
  final shellPets = controller.guardianShellPets(allPets);
  final fostered = shellPets.where((p) => !p.passedAway && p.isFoster).toList();
  sortPetsByCreatedAt(fostered);
  return fostered;
}

/// Active shared pets for the guardian dashboard, oldest first.
List<Pet> petCareDashboardSharedPets(
  List<Pet> allPets,
  PetListController controller,
) {
  final shellPets = controller.guardianShellPets(allPets);
  final shared = shellPets.where((p) => !p.passedAway && p.isShared).toList();
  sortPetsByCreatedAt(shared);
  return shared;
}

/// Whether the guardian has any active shell pets (personal or foster).
bool petCareDashboardHasAnyPets(
  List<Pet> allPets,
  PetListController controller,
) {
  final shellPets = controller.guardianShellPets(allPets);
  return shellPets.any((p) => !p.passedAway);
}
