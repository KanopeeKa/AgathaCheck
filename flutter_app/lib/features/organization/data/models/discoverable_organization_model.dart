import '../../domain/entities/discoverable_organization.dart';

class DiscoverableOrganizationModel extends DiscoverableOrganization {
  const DiscoverableOrganizationModel({
    required super.id,
    required super.name,
    super.logoUrl,
    super.photoUrl,
    super.displayLocality,
    super.town,
    super.administrativeArea,
    super.description,
  });

  factory DiscoverableOrganizationModel.fromJson(Map<String, dynamic> json) {
    return DiscoverableOrganizationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString() ?? '',
      displayLocality: json['display_locality']?.toString() ?? '',
      town: json['town']?.toString() ?? '',
      administrativeArea: json['administrative_area']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class DiscoverOrganizationsPageModel extends DiscoverOrganizationsPage {
  const DiscoverOrganizationsPageModel({
    required super.items,
    required super.page,
    required super.pageSize,
    required super.totalCount,
  });

  factory DiscoverOrganizationsPageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .map(
                (e) => DiscoverableOrganizationModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList()
        : <DiscoverableOrganization>[];

    return DiscoverOrganizationsPageModel(
      items: items,
      page: _parseInt(json['page'], fallback: 1),
      pageSize: _parseInt(json['page_size'], fallback: 20),
      totalCount: _parseInt(json['total_count'], fallback: items.length),
    );
  }
}

int _parseInt(Object? value, {required int fallback}) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
