import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../data/datasources/pet_local_datasource.dart';
import '../../data/datasources/pet_remote_datasource.dart';
import '../../data/repositories/pet_repository_impl.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/pet_repository.dart';
import '../../domain/usecases/add_pet.dart';
import '../../domain/usecases/delete_pet.dart';
import '../../domain/usecases/get_all_pets.dart';
import '../../domain/usecases/update_pet.dart';

export '../../../../core/providers/shared_preferences_provider.dart';

final petLocalDataSourceProvider = Provider<PetLocalDataSource>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  return PetLocalDataSourceImpl(ref.watch(sharedPreferencesProvider), userId: userId);
});

final petRemoteDataSourceProvider = Provider<PetRemoteDataSource>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return PetRemoteDataSourceImpl(baseUrl: baseUrl);
});

final _accessTokenProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.accessToken;
});

final petRepositoryProvider = Provider<PetRepository>((ref) {
  final local = ref.watch(petLocalDataSourceProvider);
  final remote = ref.watch(petRemoteDataSourceProvider);
  final token = ref.watch(_accessTokenProvider);
  return PetRepositoryImpl(local, remoteDataSource: remote, token: token);
});

final getAllPetsUseCaseProvider = Provider<GetAllPets>((ref) {
  return GetAllPets(ref.watch(petRepositoryProvider));
});

final addPetUseCaseProvider = Provider<AddPet>((ref) {
  return AddPet(ref.watch(petRepositoryProvider));
});

final updatePetUseCaseProvider = Provider<UpdatePet>((ref) {
  return UpdatePet(ref.watch(petRepositoryProvider));
});

final deletePetUseCaseProvider = Provider<DeletePet>((ref) {
  return DeletePet(ref.watch(petRepositoryProvider));
});

class PetListNotifier extends AsyncNotifier<List<Pet>> {
  @override
  Future<List<Pet>> build() async {
    ref.watch(authProvider);
    final pets = await ref.read(getAllPetsUseCaseProvider).call();
    final needsMigration = pets.any((p) => p.colorValue == null);
    if (needsMigration) {
      final usedColors = <int>{};
      final updated = <Pet>[];
      for (final p in pets) {
        if (p.colorValue != null) {
          usedColors.add(p.colorValue!);
          updated.add(p);
        } else {
          int color = Pet.palette[0];
          for (final c in Pet.palette) {
            if (!usedColors.contains(c)) {
              color = c;
              break;
            }
          }
          usedColors.add(color);
          final patched = p.copyWith(colorValue: color);
          await ref.read(updatePetUseCaseProvider).call(patched);
          updated.add(patched);
        }
      }
      return updated;
    }
    return pets;
  }

  Future<String> addPet({
    required String name,
    required String species,
    String breed = '',
    DateTime? dateOfBirth,
    double? weight,
    String? gender,
    String bio = '',
    String insurance = '',
    DateTime? neuteredDate,
    bool neuterDismissed = false,
    String chipId = '',
    bool chipDismissed = false,
    String? photoPath,
    String? vetId,
    int? organizationId,
  }) async {
    final existing = state.valueOrNull ?? [];
    final usedColors = existing
        .where((p) => p.colorValue != null)
        .map((p) => p.colorValue!)
        .toSet();
    int color = Pet.palette[0];
    for (final c in Pet.palette) {
      if (!usedColors.contains(c)) {
        color = c;
        break;
      }
    }
    final pet = Pet(
      id: const Uuid().v4(),
      name: name,
      species: species,
      breed: breed,
      dateOfBirth: dateOfBirth,
      weight: weight,
      gender: gender,
      bio: bio,
      insurance: insurance,
      neuteredDate: neuteredDate,
      neuterDismissed: neuterDismissed,
      chipId: chipId,
      chipDismissed: chipDismissed,
      photoPath: photoPath,
      vetId: vetId,
      colorValue: color,
      organizationId: organizationId,
    );
    await ref.read(addPetUseCaseProvider).call(pet);
    ref.invalidateSelf();
    return pet.id;
  }

  Future<void> updatePet(Pet pet) async {
    await ref.read(updatePetUseCaseProvider).call(pet);
    ref.invalidateSelf();
  }

  Future<void> deletePet(String id) async {
    final baseUrl = kIsWeb ? '' : 'http://localhost:5000';
    final prefs = ref.read(sharedPreferencesProvider);
    final token = prefs.getString('access_token') ?? '';
    try {
      await http.delete(
        Uri.parse('$baseUrl/api/pets/$id/data'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}
    await ref.read(deletePetUseCaseProvider).call(id);
    ref.invalidateSelf();
  }

  Future<bool> markPassedAway(String petId) async {
    final pets = state.valueOrNull ?? [];
    final pet = pets.where((p) => p.id == petId).firstOrNull;
    if (pet == null) return false;

    final updated = pet.copyWith(
      passedAway: true,
      colorValue: 0xFFFFFFFF,
    );
    await ref.read(updatePetUseCaseProvider).call(updated);

    final baseUrl = kIsWeb ? '' : 'http://localhost:5000';
    bool hasSharedUsers = false;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final token = prefs.getString('access_token') ?? '';
      final response = await http.post(
        Uri.parse('$baseUrl/api/pets/$petId/passed-away'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: '{"pet_name": "${pet.name}"}',
      );
      if (response.statusCode == 200) {
        final body = response.body;
        hasSharedUsers = body.contains('"notified_count"') && !body.contains('"notified_count":0');
      }
    } catch (_) {}

    ref.invalidateSelf();
    return hasSharedUsers;
  }
}

final petListProvider =
    AsyncNotifierProvider<PetListNotifier, List<Pet>>(PetListNotifier.new);

final petByIdProvider = FutureProvider.family<Pet?, String>((ref, id) async {
  final pets = await ref.watch(petListProvider.future);
  return pets.where((p) => p.id == id).firstOrNull;
});

final allPetsIncludingOrgProvider = FutureProvider<List<Pet>>((ref) async {
  final token = ref.watch(_accessTokenProvider);
  if (token == null || token.isEmpty) return [];
  final remote = ref.watch(petRemoteDataSourceProvider);
  final models = await remote.getAllPetsIncludingOrg(token);
  return models.map((m) => m.toEntity()).toList();
});
