import '../../domain/entities/foster_parent.dart';

/// Operational tabs for Manage Fosters (J1). Activity meaning from migration appendix §8.
enum ManageFostersTab { all, newFosters, fostering, recentlyFostered, inactive }

/// Approval filters — UI only until J1 Phase 2 (`approval_state` column).
enum ManageFostersApprovalFilter { underReview, approved, archived }

const _activePlacementStatuses = {
  'pending',
  'in_progress',
  'waiting_adoption_confirmation',
  'pending_adoption_conditions',
};

bool fosterHasActivePlacement(FosterParent parent) {
  if (parent.activePetCount > 0) return true;
  return parent.activePets.any(
    (p) => _activePlacementStatuses.contains(p.status),
  );
}

bool fosterMatchesManageFostersTab(FosterParent parent, ManageFostersTab tab) {
  switch (tab) {
    case ManageFostersTab.all:
      return true;
    case ManageFostersTab.fostering:
      return fosterHasActivePlacement(parent);
    case ManageFostersTab.inactive:
      return !fosterHasActivePlacement(parent);
    case ManageFostersTab.newFosters:
      return parent.isExternal && !fosterHasActivePlacement(parent);
    case ManageFostersTab.recentlyFostered:
      return false;
  }
}

List<FosterParent> filterFosterParentsForManageFosters({
  required List<FosterParent> parents,
  required ManageFostersTab tab,
}) {
  return parents
      .where((p) => fosterMatchesManageFostersTab(p, tab))
      .toList(growable: false);
}
