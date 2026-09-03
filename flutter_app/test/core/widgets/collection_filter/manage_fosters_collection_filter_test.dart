import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/widgets/collection_filter/manage_fosters_collection_filter.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/manage_fosters_providers.dart';

void main() {
  test('manage fosters approval round-trip preserves filter', () {
    for (final filter in ManageFostersApprovalFilter.values) {
      final roundTrip = manageFostersApprovalFilterFromSelections(
        selectionsFromManageFostersApprovalFilter(filter),
      );
      expect(roundTrip, filter);
    }
    expect(manageFostersApprovalFilterFromSelections(const {}), isNull);
  });
}
