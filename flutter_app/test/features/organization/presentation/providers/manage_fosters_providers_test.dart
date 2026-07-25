import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_parent.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/manage_fosters_providers.dart';

FosterParent _parent({
  required String id,
  FosterParentKind kind = FosterParentKind.member,
  FosterApprovalState approvalState = FosterApprovalState.approved,
  FosteringActivitySummary activitySummary =
      FosteringActivitySummary.notYetPlaced,
}) {
  return FosterParent(
    id: id,
    kind: kind,
    displayName: 'Test $id',
    approvalState: approvalState,
    fosteringActivitySummary: activitySummary,
  );
}

void main() {
  group('filterFosterParentsForManageFosters', () {
    final parents = [
      _parent(
        id: 'active',
        activitySummary: FosteringActivitySummary.activelyFostering,
      ),
      _parent(
        id: 'external-new',
        kind: FosterParentKind.external,
        approvalState: FosterApprovalState.underReview,
        activitySummary: FosteringActivitySummary.notYetPlaced,
      ),
      _parent(
        id: 'inactive-member',
        activitySummary: FosteringActivitySummary.inactive,
      ),
      _parent(
        id: 'archived-external',
        kind: FosterParentKind.external,
        approvalState: FosterApprovalState.archived,
        activitySummary: FosteringActivitySummary.inactive,
      ),
      _parent(
        id: 'recent',
        activitySummary: FosteringActivitySummary.recentlyEnded,
      ),
    ];

    test('all tab returns everyone', () {
      final result = filterFosterParentsForManageFosters(
        parents: parents,
        tab: ManageFostersTab.all,
      );
      expect(result.length, 5);
    });

    test('fostering tab returns actively fostering parents only', () {
      final result = filterFosterParentsForManageFosters(
        parents: parents,
        tab: ManageFostersTab.fostering,
      );
      expect(result.map((p) => p.id), ['active']);
    });

    test('new tab returns not-yet-placed fosters', () {
      final result = filterFosterParentsForManageFosters(
        parents: parents,
        tab: ManageFostersTab.newFosters,
      );
      expect(result.map((p) => p.id), ['external-new']);
    });

    test('inactive tab returns inactive fosters', () {
      final result = filterFosterParentsForManageFosters(
        parents: parents,
        tab: ManageFostersTab.inactive,
      );
      expect(
        result.map((p) => p.id),
        containsAll(['inactive-member', 'archived-external']),
      );
    });

    test('recently fostered tab returns recently ended fosters', () {
      final result = filterFosterParentsForManageFosters(
        parents: parents,
        tab: ManageFostersTab.recentlyFostered,
      );
      expect(result.map((p) => p.id), ['recent']);
    });

    test('approval filter under_review', () {
      final result = filterFosterParentsForManageFosters(
        parents: parents,
        tab: ManageFostersTab.all,
        approvalFilter: ManageFostersApprovalFilter.underReview,
      );
      expect(result.map((p) => p.id), ['external-new']);
    });

    test('approval filter archived', () {
      final result = filterFosterParentsForManageFosters(
        parents: parents,
        tab: ManageFostersTab.all,
        approvalFilter: ManageFostersApprovalFilter.archived,
      );
      expect(result.map((p) => p.id), ['archived-external']);
    });
  });
}
