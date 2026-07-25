import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_parent.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/manage_fosters_providers.dart';

FosterParent _parent({
  required String id,
  FosterParentKind kind = FosterParentKind.member,
  int activePetCount = 0,
  List<FosterParentAssignedPet> activePets = const [],
  FosterApprovalState approvalState = FosterApprovalState.approved,
}) {
  return FosterParent(
    id: id,
    kind: kind,
    displayName: 'Test $id',
    activePetCount: activePetCount,
    activePets: activePets,
    approvalState: approvalState,
  );
}

void main() {
  group('filterFosterParentsForManageFosters', () {
    final parents = [
      _parent(id: 'active', activePetCount: 1),
      _parent(
        id: 'external-new',
        kind: FosterParentKind.external,
        approvalState: FosterApprovalState.underReview,
      ),
      _parent(id: 'inactive-member'),
      _parent(
        id: 'archived-external',
        kind: FosterParentKind.external,
        approvalState: FosterApprovalState.archived,
      ),
    ];

    test('all tab returns everyone', () {
      final result = filterFosterParentsForManageFosters(
        parents: parents,
        tab: ManageFostersTab.all,
      );
      expect(result.length, 4);
    });

    test('fostering tab returns active placements only', () {
      final result = filterFosterParentsForManageFosters(
        parents: parents,
        tab: ManageFostersTab.fostering,
      );
      expect(result.map((p) => p.id), ['active']);
    });

    test('new tab returns external without placements', () {
      final result = filterFosterParentsForManageFosters(
        parents: parents,
        tab: ManageFostersTab.newFosters,
      );
      expect(
        result.map((p) => p.id),
        containsAll(['external-new', 'archived-external']),
      );
    });

    test('inactive tab returns non-fostering members', () {
      final result = filterFosterParentsForManageFosters(
        parents: parents,
        tab: ManageFostersTab.inactive,
      );
      expect(
        result.map((p) => p.id),
        containsAll(['external-new', 'inactive-member', 'archived-external']),
      );
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
