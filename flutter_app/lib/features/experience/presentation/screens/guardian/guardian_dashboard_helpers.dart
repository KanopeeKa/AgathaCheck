import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/widgets/pet_card.dart' show sortPetsByCreatedAt;
import '../../../../pet_profile/presentation/widgets/pet_tile_status_line.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';

/// Relationship wording is intentionally a presentation concern. Eligibility
/// remains owned by [PetListController].
enum GuardianTodayPetRelationship { owned, fostered, shared }

/// Care urgency in the Guardian Today presentation.
enum GuardianTodayCareUrgency { overdue, dueToday, upcoming }

/// Truthful data state for a consumer of the dashboard presentation model.
enum GuardianTodayScreenState {
  firstUse,
  allClear,
  attention,
  loading,
  partial,
  error,
}

/// Stable, grouped care values for the Guardian dashboard.
class GuardianTodayCarePriorities {
  const GuardianTodayCarePriorities._({
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

  static GuardianTodayCarePriorities forPets({
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
    final buckets = <GuardianTodayCareUrgency, List<(int, HealthEntry)>>{
      GuardianTodayCareUrgency.overdue: [],
      GuardianTodayCareUrgency.dueToday: [],
      GuardianTodayCareUrgency.upcoming: [],
    };

    for (final item in indexed) {
      final urgency = guardianTodayCareUrgency(item.$2, now);
      if (urgency != null) buckets[urgency]!.add(item);
    }

    List<HealthEntry> sorted(GuardianTodayCareUrgency urgency) {
      final entries = buckets[urgency]!
        ..sort((a, b) {
          final aDate = a.$2.nextDueDate ?? DateTime(9999);
          final bDate = b.$2.nextDueDate ?? DateTime(9999);
          final byDate = aDate.compareTo(bDate);
          return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
        });
      return List<HealthEntry>.unmodifiable(entries.map((item) => item.$2));
    }

    return GuardianTodayCarePriorities._(
      overdue: sorted(GuardianTodayCareUrgency.overdue),
      dueToday: sorted(GuardianTodayCareUrgency.dueToday),
      upcoming: sorted(GuardianTodayCareUrgency.upcoming),
    );
  }
}

/// Capped pet values consumed by dashboard-only components.
class GuardianTodayPetPreview {
  const GuardianTodayPetPreview._({
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
class GuardianTodayCareSummary {
  const GuardianTodayCareSummary._({required this.priorities});

  final GuardianTodayCarePriorities priorities;

  List<HealthEntry> get dueEntries => priorities.all;
  int get overdueCount => priorities.overdue.length;
  int get dueTodayCount => priorities.dueToday.length;
  int get upcomingCount => priorities.upcoming.length;

  int get attentionCount => priorities.attentionCount;
  bool get hasAttention => attentionCount > 0;

  static GuardianTodayCareSummary forPets({
    required List<HealthEntry> entries,
    required List<Pet> pets,
    DateTime? now,
  }) {
    final priorities = GuardianTodayCarePriorities.forPets(
      entries: entries,
      pets: pets,
      now: now ?? DateTime.now(),
    );
    return GuardianTodayCareSummary._(priorities: priorities);
  }
}

/// Uses the existing reminder-window convention, with an injected clock so
/// deterministic tests and future UI states share the same date boundary.
GuardianTodayCareUrgency? guardianTodayCareUrgency(
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
  if (dueDay.isBefore(today)) return GuardianTodayCareUrgency.overdue;
  if (dueDay == today) return GuardianTodayCareUrgency.dueToday;
  final daysUntilDue = dueDay.difference(today).inDays;
  if (daysUntilDue <= entry.remindDaysBefore) {
    return GuardianTodayCareUrgency.upcoming;
  }
  return null;
}

GuardianTodayPetRelationship guardianTodayPetRelationship(Pet pet) {
  if (pet.isShared) return GuardianTodayPetRelationship.shared;
  if (pet.isFoster) return GuardianTodayPetRelationship.fostered;
  return GuardianTodayPetRelationship.owned;
}

GuardianTodayScreenState guardianTodayScreenState({
  required bool hasPets,
  required bool hasCareData,
  required bool isLoading,
  required bool hasError,
  required bool hasAttention,
}) {
  if (hasError) return GuardianTodayScreenState.error;
  if (isLoading && !hasCareData) return GuardianTodayScreenState.loading;
  if (!hasPets) return GuardianTodayScreenState.firstUse;
  if (!hasCareData) return GuardianTodayScreenState.partial;
  return hasAttention
      ? GuardianTodayScreenState.attention
      : GuardianTodayScreenState.allClear;
}

/// Selects all active shell pets for the dashboard rail, attention-first when
/// [careSummary] is available.
List<Pet> guardianTodayRailPets(
  List<Pet> allPets,
  PetListController controller,
  GuardianTodayCareSummary? careSummary,
) {
  return _guardianDashboardShellPetsSorted(
    allPets,
    controller,
    careSummary,
  );
}

/// Selects a stable, attention-first dashboard preview without changing any
/// ownership or visibility decisions made by [PetListController].
List<Pet> guardianTodayPreviewPets(
  List<Pet> allPets,
  PetListController controller,
  GuardianTodayCareSummary careSummary,
) {
  return guardianTodayRailPets(allPets, controller, careSummary);
}

List<Pet> _guardianDashboardShellPetsSorted(
  List<Pet> allPets,
  PetListController controller,
  GuardianTodayCareSummary? careSummary,
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
      GuardianTodayCareUrgency.overdue => 0,
      GuardianTodayCareUrgency.dueToday => 1,
      GuardianTodayCareUrgency.upcoming => 2,
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

GuardianTodayPetPreview guardianTodayPetPreview(
  List<Pet> allPets,
  PetListController controller,
  GuardianTodayCareSummary careSummary,
) {
  final sorted = _guardianDashboardShellPetsSorted(
    allPets,
    controller,
    careSummary,
  );
  final visible = sorted.take(GuardianTodayPetPreview.visibleLimit).toList();
  return GuardianTodayPetPreview._(
    visiblePets: List<Pet>.unmodifiable(visible),
    overflowCount: (sorted.length - GuardianTodayPetPreview.visibleLimit)
        .clamp(0, sorted.length)
        .toInt(),
  );
}

/// Returns the strongest visible care status for a pet in the dashboard
/// preview. The UI supplies the localized wording.
GuardianTodayPetCareState guardianTodayPetCareState(
  Pet pet,
  GuardianTodayCareSummary careSummary,
) {
  if (careSummary.priorities.overdue.any((entry) => entry.petId == pet.id)) {
    return GuardianTodayPetCareState.overdue;
  }
  if (careSummary.priorities.dueToday.any((entry) => entry.petId == pet.id)) {
    return GuardianTodayPetCareState.dueToday;
  }
  if (careSummary.priorities.upcoming.any((entry) => entry.petId == pet.id)) {
    return GuardianTodayPetCareState.upcoming;
  }
  return GuardianTodayPetCareState.clear;
}

enum GuardianTodayPetCareState { overdue, dueToday, upcoming, clear }

PetTileCareUrgency petTileCareUrgencyFor(GuardianTodayPetCareState state) {
  return switch (state) {
    GuardianTodayPetCareState.overdue => PetTileCareUrgency.overdue,
    GuardianTodayPetCareState.dueToday => PetTileCareUrgency.dueToday,
    GuardianTodayPetCareState.upcoming => PetTileCareUrgency.upcoming,
    GuardianTodayPetCareState.clear => PetTileCareUrgency.clear,
  };
}

GuardianTodayCareUrgency? _urgencyForEntry(
  HealthEntry entry,
  GuardianTodayCareSummary summary,
) {
  if (summary.priorities.overdue.contains(entry)) {
    return GuardianTodayCareUrgency.overdue;
  }
  if (summary.priorities.dueToday.contains(entry)) {
    return GuardianTodayCareUrgency.dueToday;
  }
  if (summary.priorities.upcoming.contains(entry)) {
    return GuardianTodayCareUrgency.upcoming;
  }
  return null;
}

/// Active owned pets (not shared or foster) for the guardian dashboard, oldest first.
List<Pet> guardianDashboardPersonalPets(
  List<Pet> allPets,
  PetListController controller,
) {
  final shellPets = controller.guardianShellPets(allPets);
  final owned = controller.getOwnedPets(shellPets);
  sortPetsByCreatedAt(owned);
  return owned;
}

/// Active foster pets for the guardian dashboard, oldest first.
List<Pet> guardianDashboardFosterPets(
  List<Pet> allPets,
  PetListController controller,
) {
  final shellPets = controller.guardianShellPets(allPets);
  final fostered = shellPets.where((p) => !p.passedAway && p.isFoster).toList();
  sortPetsByCreatedAt(fostered);
  return fostered;
}

/// Active shared pets for the guardian dashboard, oldest first.
List<Pet> guardianDashboardSharedPets(
  List<Pet> allPets,
  PetListController controller,
) {
  final shellPets = controller.guardianShellPets(allPets);
  final shared = shellPets.where((p) => !p.passedAway && p.isShared).toList();
  sortPetsByCreatedAt(shared);
  return shared;
}

/// Whether the guardian has any active shell pets (personal or foster).
bool guardianDashboardHasAnyPets(
  List<Pet> allPets,
  PetListController controller,
) {
  final shellPets = controller.guardianShellPets(allPets);
  return shellPets.any((p) => !p.passedAway);
}
