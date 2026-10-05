import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_base_url_provider.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../data/households_api.dart';
import '../data/people_api.dart';
import '../data/people_api_exception.dart';
import '../data/people_repository_impl.dart';
import '../domain/entities/contact_detail.dart';
import '../domain/entities/contact_summary.dart';
import '../domain/entities/household.dart';
import '../domain/entities/pet_people.dart';
import '../domain/entities/related_care.dart';
import '../domain/entities/roster.dart';
import '../domain/repositories/people_repository.dart';

final peopleApiProvider = Provider<PeopleApi>((ref) {
  final token = ref.watch(authProvider).accessToken;
  return PeopleApi(
    baseUrl: ref.watch(apiBaseUrlProvider),
    client: ref.watch(authHttpClientProvider),
    token: token,
  );
});

final householdsApiProvider = Provider<HouseholdsApi>((ref) {
  final token = ref.watch(authProvider).accessToken;
  return HouseholdsApi(
    baseUrl: ref.watch(apiBaseUrlProvider),
    client: ref.watch(authHttpClientProvider),
    token: token,
  );
});

final peopleRepositoryProvider = Provider<PeopleRepository>((ref) {
  return PeopleRepositoryImpl(ref.watch(peopleApiProvider));
});

final householdsRepositoryProvider = Provider<HouseholdsRepository>((ref) {
  return HouseholdsRepositoryImpl(ref.watch(householdsApiProvider));
});

final rosterProvider = AsyncNotifierProvider<RosterNotifier, Roster>(
  RosterNotifier.new,
);

class RosterNotifier extends AsyncNotifier<Roster> {
  @override
  Future<Roster> build() async {
    final repo = ref.read(peopleRepositoryProvider);
    return repo.fetchRoster(includeInactive: true);
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    state = previous == null ? const AsyncLoading() : AsyncData(previous);
    state = await AsyncValue.guard(() async {
      final repo = ref.read(peopleRepositoryProvider);
      return repo.fetchRoster(includeInactive: true);
    });
  }
}

final personSummaryProvider = Provider.family<ContactSummary?, String>((
  ref,
  id,
) {
  final roster = ref.watch(rosterProvider).valueOrNull;
  return roster?.summaryById(id);
});

final personDetailProvider = FutureProvider.autoDispose
    .family<ContactDetail?, String>((ref, id) async {
      final repo = ref.watch(peopleRepositoryProvider);
      try {
        return await repo.fetchContactDetail(id);
      } on PeopleApiException catch (e) {
        if (e.statusCode == 404) return null;
        rethrow;
      }
    });

final relatedCareProvider = FutureProvider.autoDispose
    .family<RelatedCare?, String>((ref, id) async {
      final repo = ref.watch(peopleRepositoryProvider);
      try {
        return await repo.fetchRelatedCare(id);
      } on PeopleApiException catch (e) {
        if (e.statusCode == 404) return null;
        rethrow;
      }
    });

final petPeopleProvider = FutureProvider.autoDispose.family<PetPeople?, String>(
  (ref, petId) async {
    final repo = ref.watch(peopleRepositoryProvider);
    try {
      return await repo.fetchPetPeople(petId);
    } on PeopleApiException catch (e) {
      if (e.statusCode == 403 || e.statusCode == 404) return null;
      rethrow;
    }
  },
);

final peopleHouseholdsProvider = FutureProvider<List<Household>>((ref) async {
  final repo = ref.watch(householdsRepositoryProvider);
  return repo.listHouseholds();
});

final householdDetailProvider = FutureProvider.autoDispose
    .family<Household?, String>((ref, householdId) async {
      final repo = ref.watch(householdsRepositoryProvider);
      try {
        return await repo.fetchHouseholdDetail(householdId);
      } catch (_) {
        final roster = ref.read(rosterProvider).valueOrNull;
        for (final h in roster?.households ?? const <Household>[]) {
          if (h.id == householdId) return h;
        }
        final listed = await ref.read(peopleHouseholdsProvider.future);
        return listed.where((h) => h.id == householdId).firstOrNull;
      }
    });

/// Resolves a legacy `vets` row id to a People contact id (deep links).
final legacyVetContactIdProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, vetId) async {
      final repo = ref.watch(peopleRepositoryProvider);
      return repo.contactIdForLegacyVet(vetId);
    });
