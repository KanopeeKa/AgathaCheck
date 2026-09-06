import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/widgets/pet_card.dart'
    show sortPetsByCreatedAt;
import '../../../../pet_profile/presentation/widgets/pet_tile_status_line.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';

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
  }) {
    final petIds = pets
        .where((pet) => !pet.passedAway)
        .map((pet) => pet.id)
        .toSet();
    final indexed = entries.indexed.where(
      (item) => petIds.contains(item.$2.petId),
    );
    final buckets = <PetCareTodayCareUrgency, List<(int, HealthEntry)>>{
      PetCareTodayCareUrgency.overdue: [],
      PetCareTodayCareUrgency.dueToday: [],
      PetCareTodayCareUrgency.upcoming: [],
    };

    for (final item in indexed) {
      final urgency = petCareTodayCareUrgency(item.$2, now);
      if (urgency != null) buckets[urgency]!.add(item);
    }

    List<HealthEntry> sorted(PetCareTodayCareUrgency urgency) {
      final entries = buckets[urgency]!
        ..sort((a, b) {
          final aDate = a.$2.nextDueDate ?? DateTime(9999);
          final bDate = b.$2.nextDueDate ?? DateTime(9999);
          final byDate = aDate.compareTo(bDate);
          return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
        });
      return List<HealthEntry>.unmodifiable(entries.map((item) => item.$2));
    }

    return PetCareTodayCarePriorities._(
      overdue: sorted(PetCareTodayCareUrgency.overdue),
      dueToday: sorted(PetCareTodayCareUrgency.dueToday),
      upcoming: sorted(PetCareTodayCareUrgency.upcoming),
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

/// Uses the existing reminder-window convention, with an injected clock so
/// deterministic tests and future UI states share the same date boundary.
PetCareTodayCareUrgency? petCareTodayCareUrgency(
  HealthEntry entry,
  DateTime now,
) {
  if (entry.isCompleted || entry.nextDueDate == null) return null;
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(
    entry.nextDueDate!.year,
    entry.nextDueDate!.month,
    entry.nextDueDate!.day,
  );
  if (dueDay.isBefore(today)) return PetCareTodayCareUrgency.overdue;
  if (dueDay == today) return PetCareTodayCareUrgency.dueToday;
  final daysUntilDue = dueDay.difference(today).inDays;
  if (daysUntilDue <= entry.remindDaysBefore) {
    return PetCareTodayCareUrgency.upcoming;
  }
  return null;
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

/// Returns the strongest visible care status for a pet in the dashboard
/// preview. The UI supplies the localized wording.
PetCareTodayPetCareState petCareTodayPetCareState(
  Pet pet,
  PetCareTodayCareSummary careSummary,
) {
  if (careSummary.priorities.overdue.any((entry) => entry.petId == pet.id)) {
    return PetCareTodayPetCareState.overdue;
  }
  if (careSummary.priorities.dueToday.any((entry) => entry.petId == pet.id)) {
    return PetCareTodayPetCareState.dueToday;
  }
  if (careSummary.priorities.upcoming.any((entry) => entry.petId == pet.id)) {
    return PetCareTodayPetCareState.upcoming;
  }
  return PetCareTodayPetCareState.clear;
}

enum PetCareTodayPetCareState { overdue, dueToday, upcoming, clear }

PetTileCareUrgency petTileCareUrgencyFor(PetCareTodayPetCareState state) {
  return switch (state) {
    PetCareTodayPetCareState.overdue => PetTileCareUrgency.overdue,
    PetCareTodayPetCareState.dueToday => PetTileCareUrgency.dueToday,
    PetCareTodayPetCareState.upcoming => PetTileCareUrgency.upcoming,
    PetCareTodayPetCareState.clear => PetTileCareUrgency.clear,
  };
}

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

/// Active owned pets (not shared or foster) for the guardian dashboard, oldest first.
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
