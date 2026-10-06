import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/people/people.dart';

List<CareProviderContactOption> careProviderOptionsFromRoster(Roster? roster) {
  if (roster == null) return const [];
  final options = <CareProviderContactOption>[];
  for (final contact in roster.contacts) {
    if (contact.isInactive) continue;
    options.add(CareProviderContactOption(id: contact.id, name: contact.name));
  }
  options.sort((a, b) => a.name.compareTo(b.name));
  return options;
}

/// Wires People roster into health-tracking care provider pickers (D-CIE-016).
Override careProviderContactOptionsOverride() {
  return careProviderContactOptionsProvider.overrideWith((ref) {
    return ref
        .watch(rosterProvider)
        .when(
          data: (roster) => AsyncData(careProviderOptionsFromRoster(roster)),
          loading: () => const AsyncLoading(),
          error: (e, st) => AsyncError(e, st),
        );
  });
}
