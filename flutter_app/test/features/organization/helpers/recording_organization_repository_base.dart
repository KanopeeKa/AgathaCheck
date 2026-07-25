import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/domain/repositories/organization_repository.dart';

/// Shared recording state for [RecordingOrganizationRepository] test fakes.
abstract class RecordingOrganizationRepositoryBase
    implements OrganizationRepository {
  final List<Organization> created = [];
  final List<Organization> updated = [];
  final List<String> deleted = [];
  final List<(String, String, OrgMemberRole)> roleChanges = [];
}
