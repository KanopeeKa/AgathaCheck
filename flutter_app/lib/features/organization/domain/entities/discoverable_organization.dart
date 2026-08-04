import 'organization.dart';

class DiscoverableOrganization {
  const DiscoverableOrganization({
    required this.id,
    required this.name,
    this.type = OrganizationType.professional,
    this.logoUrl = '',
    this.photoUrl = '',
    this.displayLocality = '',
    this.town = '',
    this.administrativeArea = '',
    this.description = '',
  });

  final String id;
  final String name;
  final OrganizationType type;
  final String logoUrl;
  final String photoUrl;
  final String displayLocality;
  final String town;
  final String administrativeArea;
  final String description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoverableOrganization &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DiscoverOrganizationsPage {
  const DiscoverOrganizationsPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  final List<DiscoverableOrganization> items;
  final int page;
  final int pageSize;
  final int totalCount;
}
