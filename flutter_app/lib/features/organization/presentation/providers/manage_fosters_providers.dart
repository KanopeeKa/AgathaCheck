import '../../domain/entities/foster_parent.dart';

/// Operational tabs for Manage Fosters (J1). Activity meaning from J3 read model.
enum ManageFostersTab { all, newFosters, fostering, recentlyFostered, inactive }

/// Approval filters backed by `approval_state` on shelter–foster relationships (J1 Phase 2).
enum ManageFostersApprovalFilter { underReview, approved, archived }

bool fosterMatchesManageFostersTab(FosterParent parent, ManageFostersTab tab) {
  switch (tab) {
    case ManageFostersTab.all:
      return true;
    case ManageFostersTab.fostering:
      return parent.fosteringActivitySummary ==
          FosteringActivitySummary.activelyFostering;
    case ManageFostersTab.inactive:
      return parent.fosteringActivitySummary ==
          FosteringActivitySummary.inactive;
    case ManageFostersTab.newFosters:
      return parent.fosteringActivitySummary ==
          FosteringActivitySummary.notYetPlaced;
    case ManageFostersTab.recentlyFostered:
      return parent.fosteringActivitySummary ==
          FosteringActivitySummary.recentlyEnded;
  }
}

FosterApprovalState? approvalStateForFilter(
  ManageFostersApprovalFilter filter,
) {
  switch (filter) {
    case ManageFostersApprovalFilter.underReview:
      return FosterApprovalState.underReview;
    case ManageFostersApprovalFilter.approved:
      return FosterApprovalState.approved;
    case ManageFostersApprovalFilter.archived:
      return FosterApprovalState.archived;
  }
}

bool fosterMatchesApprovalFilter(
  FosterParent parent,
  ManageFostersApprovalFilter? filter,
) {
  if (filter == null) return true;
  return parent.approvalState == approvalStateForFilter(filter);
}

List<FosterParent> filterFosterParentsForManageFosters({
  required List<FosterParent> parents,
  required ManageFostersTab tab,
  ManageFostersApprovalFilter? approvalFilter,
}) {
  return parents
      .where((p) => fosterMatchesManageFostersTab(p, tab))
      .where((p) => fosterMatchesApprovalFilter(p, approvalFilter))
      .toList(growable: false);
}
