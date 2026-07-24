import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_parent.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/manage_fosters_providers.dart';

FosterParent _parent({
  required String id,
  FosterParentKind kind = FosterParentKind.member,
  int activePetCount = 0,
  List<FosterParentAssignedPet> activePets = const [],
}) {
  return FosterParent(
    id: id,
    kind: kind,
    displayName: 'Test $id',
    activePetCount: activePetCount,
    activePets: activePets,
  );
}

void main() {
  group('filterFosterParentsForManageFosters', () {
    final parents = [
      _parent(id: 'active', activePetCount: 1),
      _parent(id: 'external-new', kind: FosterParentKind.external),
      _parent(id: 'inactive-member'),
    ];

    test('all tab returns everyone', () {
      final result = filterFosterParentsForManageFosters(
        parents: parents,
        tab: ManageFostersTab.all,
      );
      expect(result.length, 3);
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
      expect(result.map((p) => p.id), ['external-new']);
    });

    test('inactive tab returns non-fostering members', () {
      final result = filterFosterParentsForManageFosters(
        parents: parents,
        tab: ManageFostersTab.inactive,
      );
      expect(result.map((p) => p.id), containsAll(['external-new', 'inactive-member']));
    });
  });
}
