import '../datasources/organization_remote_datasource.dart';
import 'organization_repository_impl_base.dart';
import 'organization_repository_impl_custody.dart';
import 'organization_repository_impl_foster.dart';
import 'organization_repository_impl_pets.dart';

class OrganizationRepositoryImpl extends OrganizationRepositoryImplBase
    with
        OrganizationRepositoryPetsMixin,
        OrganizationRepositoryFosterMixin,
        OrganizationRepositoryCustodyMixin {
  OrganizationRepositoryImpl(OrganizationRemoteDataSource dataSource)
    : super(dataSource);
}
