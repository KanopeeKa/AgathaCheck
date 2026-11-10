import '../../../pet_profile/screens/widgets/pet_care_global_events_filters.dart';

/// Deep-link pet selection for global All care (`/pc/events?pet=id1,id2`).
abstract final class GlobalEventsPetQuery {
  static const queryParam = 'pet';

  static Set<String> petIdsFromUri(Uri uri, {Iterable<String>? knownPetIds}) {
    final raw = uri.queryParameters[queryParam];
    if (raw == null || raw.isEmpty) return {};
    final ids = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (knownPetIds == null) return ids;
    final known = knownPetIds.toSet();
    return ids.where(known.contains).toSet();
  }

  static Map<String, String> petIdsToQueryParameters(
    Set<String> petIds, {
    Map<String, String> base = const {},
  }) {
    final out = Map<String, String>.from(base);
    if (petIds.isEmpty) {
      out.remove(queryParam);
    } else {
      final sorted = petIds.toList()..sort();
      out[queryParam] = sorted.join(',');
    }
    return out;
  }

  static PetCareGlobalEventsFilters applyPetIdsFromUri(
    PetCareGlobalEventsFilters filters,
    Uri uri, {
    required Iterable<String> knownPetIds,
  }) {
    final fromUri = petIdsFromUri(uri, knownPetIds: knownPetIds);
    if (fromUri == filters.petIds) return filters;
    return filters.copyWith(petIds: fromUri);
  }
}
