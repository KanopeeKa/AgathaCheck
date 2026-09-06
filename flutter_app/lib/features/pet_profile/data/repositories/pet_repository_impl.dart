import 'package:flutter/foundation.dart';

import '../../domain/entities/pet.dart';
import '../../domain/repositories/pet_repository.dart';
import '../datasources/pet_local_datasource.dart';
import '../datasources/pet_remote_datasource.dart';
import '../models/pet_model.dart';
import '../utils/pet_photo_bytes.dart';

class PetRepositoryImpl implements PetRepository {
  PetRepositoryImpl(this._localDataSource, {this.remoteDataSource, this.token});

  final PetLocalDataSource _localDataSource;
  final PetRemoteDataSource? remoteDataSource;
  final String? token;

  @override
  Future<List<Pet>> getAllPets() async {
    if (remoteDataSource != null && token != null && token!.isNotEmpty) {
      try {
        final remotePets = await remoteDataSource!.getAllPetsIncludingOrg(
          token!,
        );
        final localPets = await _localDataSource.getAllPets();
        final merged = <PetModel>[];
        for (final rp in remotePets) {
          final localMatch = localPets
              .where((lp) => lp.id == rp.id)
              .firstOrNull;
          if (localMatch != null &&
              localMatch.photoPath != null &&
              localMatch.photoPath!.startsWith('data:')) {
            merged.add(
              PetModel(
                id: rp.id,
                name: rp.name,
                species: rp.species,
                breed: rp.breed,
                dateOfBirth: rp.dateOfBirth,
                weight: rp.weight,
                gender: rp.gender,
                bio: rp.bio,
                insurance: rp.insurance,
                neuteredDate: rp.neuteredDate,
                neuterDismissed: rp.neuterDismissed,
                chipId: rp.chipId,
                chipDismissed: rp.chipDismissed,
                photoPath: localMatch.photoPath,
                vetId: rp.vetId,
                colorValue: rp.colorValue,
                passedAway: rp.passedAway,
                isShared: rp.isShared,
                isFoster: rp.isFoster,
                organizationId: rp.organizationId,
                organizationName: rp.organizationName,
              ),
            );
          } else {
            merged.add(rp);
          }
        }
        // The server is the source of truth. Local-only pets (not present
        // remotely) are intentionally NOT re-pushed: doing so resurrected pets
        // that were deleted server-side or whose creation had failed. Dropping
        // them here lets _saveAllLocal prune the stale local cache entries.
        await _saveAllLocal(merged);
        return merged.map((m) => m.toEntity()).toList();
      } on PetRemoteException catch (e) {
        debugPrint(
          'PetRepository: Remote error (${e.statusCode}): ${e.message}',
        );
      } catch (e) {
        debugPrint('PetRepository: Network error, using local cache: $e');
      }
    }
    final models = await _localDataSource.getAllPets();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Pet?> getPetById(String id) async {
    final model = await _localDataSource.getPetById(id);
    return model?.toEntity();
  }

  Future<PetModel> _uploadPendingPhotoIfNeeded(
    PetModel remotePet,
    String? pendingPhotoPath,
  ) async {
    if (remoteDataSource == null || token == null || token!.isEmpty) {
      return remotePet;
    }
    if (!isPendingPetPhotoUpload(pendingPhotoPath)) {
      return remotePet;
    }
    final bytes = decodePendingPetPhotoBytes(pendingPhotoPath!);
    final filename = defaultPetPhotoFilename('pet.jpg');
    return remoteDataSource!.uploadPetPhoto(
      remotePet.id,
      bytes,
      filename,
      token!,
    );
  }

  @override
  Future<Pet> addPet(Pet pet) async {
    final model = PetModel.fromEntity(pet);
    final saved = await _localDataSource.addPet(model);
    if (remoteDataSource != null && token != null && token!.isNotEmpty) {
      try {
        final remotePet = await remoteDataSource!.createPet(model, token!);
        final synced = await _uploadPendingPhotoIfNeeded(
          remotePet,
          model.photoPath,
        );
        await _localDataSource.updatePet(synced);
        return synced.toEntity();
      } catch (e) {
        await _localDataSource.deletePet(model.id);
        debugPrint('PetRepository: Failed to save pet to server: $e');
        rethrow;
      }
    }
    return saved.toEntity();
  }

  @override
  Future<Pet> updatePet(Pet pet) async {
    final model = PetModel.fromEntity(pet);
    final prior = await _localDataSource.getPetById(model.id);
    final saved = await _localDataSource.updatePet(model);
    if (remoteDataSource != null && token != null && token!.isNotEmpty) {
      try {
        final remotePet = await remoteDataSource!.updatePet(model, token!);
        final synced = await _uploadPendingPhotoIfNeeded(
          remotePet,
          model.photoPath,
        );
        await _localDataSource.updatePet(synced);
        return synced.toEntity();
      } catch (e) {
        if (prior != null) {
          await _localDataSource.updatePet(prior);
        } else {
          await _localDataSource.deletePet(model.id);
        }
        debugPrint('PetRepository: Failed to update pet on server: $e');
        rethrow;
      }
    }
    return saved.toEntity();
  }

  @override
  Future<void> deletePet(String id) async {
    final prior = await _localDataSource.getPetById(id);
    await _localDataSource.deletePet(id);
    if (remoteDataSource != null && token != null && token!.isNotEmpty) {
      try {
        await remoteDataSource!.deletePet(id, token!);
      } catch (e) {
        if (prior != null) {
          await _localDataSource.addPet(prior);
        }
        debugPrint('PetRepository: Failed to delete pet from server: $e');
        rethrow;
      }
    }
  }

  @override
  Future<void> deletePetWithDataCleanup(String id) async {
    if (remoteDataSource != null && token != null && token!.isNotEmpty) {
      try {
        await remoteDataSource!.deletePetData(id, token!);
      } catch (e) {
        debugPrint('PetRepository: cascade delete of pet data failed: $e');
      }
    }
    await deletePet(id);
  }

  @override
  Future<bool> markPassedAway(Pet pet) async {
    final updated = pet.copyWith(passedAway: true, colorValue: 0xFFFFFFFF);
    await updatePet(updated);
    if (remoteDataSource == null || token == null || token!.isEmpty) {
      return false;
    }
    try {
      final count = await remoteDataSource!.notifyPassedAway(
        pet.id,
        pet.name,
        token!,
      );
      return count > 0;
    } catch (e) {
      debugPrint('PetRepository: passed-away notification failed: $e');
      return false;
    }
  }

  Future<void> _saveAllLocal(List<PetModel> pets) async {
    final existing = await _localDataSource.getAllPets();
    final existingIds = existing.map((p) => p.id).toSet();
    final newIds = pets.map((p) => p.id).toSet();
    for (final id in existingIds) {
      if (!newIds.contains(id)) {
        await _localDataSource.deletePet(id);
      }
    }
    for (final pet in pets) {
      if (existingIds.contains(pet.id)) {
        await _localDataSource.updatePet(pet);
      } else {
        await _localDataSource.addPet(pet);
      }
    }
  }
}
