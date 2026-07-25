import '../datasources/organization_remote_datasource.dart';
import 'organization_repository_impl_base.dart';
import 'organization_repository_impl_custody.dart';
import 'organization_repository_impl_foster.dart';
import 'organization_repository_impl_foster_requests.dart';
import 'organization_repository_impl_pets.dart';
import 'organization_repository_impl_screening.dart';

class OrganizationRepositoryImpl extends OrganizationRepositoryImplBase
    with
        OrganizationRepositoryPetsMixin,
        OrganizationRepositoryFosterMixin,
        OrganizationRepositoryFosterRequestsMixin,
        OrganizationRepositoryScreeningMixin,
        OrganizationRepositoryCustodyMixin {
  OrganizationRepositoryImpl(OrganizationRemoteDataSource dataSource)
    : super(dataSource);
}
