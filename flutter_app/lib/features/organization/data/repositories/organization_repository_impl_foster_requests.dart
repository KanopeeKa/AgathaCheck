import '../../domain/entities/foster_request.dart';
import '../../domain/repositories/organization_repository.dart';
import 'organization_repository_impl_base.dart';

mixin OrganizationRepositoryFosterRequestsMixin on OrganizationRepositoryImplBase {
  @override
  Future<List<String>> getEligibleFosterTargetIds(
    String orgId, {
    required List<String> petIds,
    required String token,
  }) async {
    final rows = await dataSource.getEligibleFosterTargets(
      orgId,
      petIds: petIds,
      token: token,
    );
    return rows
        .map((row) => row['org_foster_parent_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }
}
