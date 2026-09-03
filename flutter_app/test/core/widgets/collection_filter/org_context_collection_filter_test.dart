import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/widgets/collection_filter/org_context_collection_filter.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  final l = lookupAppLocalizations(const Locale('en'));

  test('pet list org context round-trip preserves filter values', () {
    for (final filter in <String?>[null, '_personal', '_fostered', 'Shelter A']) {
      final roundTrip = orgContextNameFilterFromSelections(
        orgContextSelectionsFromNameFilter(filter),
      );
      expect(roundTrip, filter);
    }
  });

  test('vet org context round-trip preserves filter values', () {
    for (final filter in <String?>[null, '_personal', 'org-123']) {
      final roundTrip = orgContextIdFilterFromSelections(
        orgContextSelectionsFromIdFilter(filter),
      );
      expect(roundTrip, filter);
    }
  });

  test('buildPetListOrgContextDimensions includes fostered when requested', () {
    final dimensions = buildPetListOrgContextDimensions(
      l: l,
      orgNames: const ['Shelter A'],
      showFosteredChoice: true,
    );
    expect(dimensions.single.choices.map((c) => c.label), contains(l.myFosteredPets));
  });
}
