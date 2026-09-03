import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/widgets/collection_filter/org_pets_collection_filter.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_pets_care_utils.dart';

void main() {
  test('org pets refinement round-trip preserves active filters', () {
    const filters = {OrgPetsActiveFilter.name, OrgPetsActiveFilter.fosteredBy};
    final roundTrip = orgPetsActiveFiltersFromSelections(
      selectionsFromOrgPetsActiveFilters(filters),
    );
    expect(roundTrip, filters);
  });
}
