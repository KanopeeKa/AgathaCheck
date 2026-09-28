import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/people_remote_datasource.dart';
import '../../data/models/people_contact_model.dart';
import '../../domain/entities/people_contact.dart';

final peopleRemoteDataSourceProvider = Provider<PeopleRemoteDataSource>((ref) {
  return PeopleRemoteDataSourceImpl(
    baseUrl: ref.watch(apiBaseUrlProvider),
    token: ref.watch(authProvider).accessToken,
    client: ref.watch(authHttpClientProvider),
  );
});

final peopleContactsProvider =
    AsyncNotifierProvider<PeopleContactsNotifier, List<PeopleContact>>(() {
      return PeopleContactsNotifier();
    });

class PeopleContactsNotifier extends AsyncNotifier<List<PeopleContact>> {
  @override
  Future<List<PeopleContact>> build() async {
    final ds = ref.read(peopleRemoteDataSourceProvider);
    final models = await ds.listContacts();
    return models.map((m) => m.toEntity()).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final ds = ref.read(peopleRemoteDataSourceProvider);
      final models = await ds.listContacts();
      return models.map((m) => m.toEntity()).toList();
    });
  }

  Future<void> addContact(PeopleContactModel draft) async {
    final ds = ref.read(peopleRemoteDataSourceProvider);
    await ds.createContact(draft);
    await refresh();
  }

  Future<void> updateContact(PeopleContactModel model) async {
    final ds = ref.read(peopleRemoteDataSourceProvider);
    await ds.updateContact(
      model.id,
      model.toPatchJson(privateNote: model.privateNote),
    );
    await refresh();
  }

  Future<void> deleteContact(String id) async {
    final ds = ref.read(peopleRemoteDataSourceProvider);
    await ds.deleteContact(id);
    await refresh();
  }
}

final peopleContactByIdProvider = Provider.family<PeopleContact?, String>((
  ref,
  id,
) {
  final async = ref.watch(peopleContactsProvider);
  return async.valueOrNull?.where((c) => c.id == id).firstOrNull;
});
