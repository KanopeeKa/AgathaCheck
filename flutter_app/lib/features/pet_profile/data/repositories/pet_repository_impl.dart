import 'package:flutter/foundation.dart';

import '../../domain/entities/pet.dart';
import '../../domain/repositories/pet_repository.dart';
import '../datasources/pet_local_datasource.dart';
import '../datasources/pet_remote_datasource.dart';
import '../models/pet_model.dart';

class PetRepositoryImpl implements PetRepository {
  PetRepositoryImpl(this._localDataSource, {this.remoteDataSource, this.token});

  final PetLocalDataSource _localDataSource;
  final PetRemoteDataSource? remoteDataSource;
  final String? token;

  @override
  Future<List<Pet>> getAllPets() async {
    if (remoteDataSource != null && token != null && token!.isNotEmpty) {
      try {
        final remotePets = await remoteDataSource!.getAllPetsIncludingOrg(token!);
        final localPets = await _localDataSource.getAllPets();
        final remoteIds = remotePets.map((p) => p.id).toSet();
        final merged = <PetModel>[];
        for (final rp in remotePets) {
          final localMatch = localPets.where((lp) => lp.id == rp.id).firstOrNull;
          if (localMatch != null && localMatch.photoPath != null && localMatch.photoPath!.startsWith('data:')) {
            merged.add(PetModel(
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
              organizationId: rp.organizationId,
              organizationName: rp.organizationName,
            ));
          } else {
            merged.add(rp);
          }
        }
        for (final lp in localPets) {
          if (!remoteIds.contains(lp.id)) {
            try {
              await remoteDataSource!.createPet(lp, token!);
            } catch (e) {
              debugPrint('PetRepository: Failed to push local pet ${lp.id} to server: $e');
            }
            merged.add(lp);
          }
        }
        await _saveAllLocal(merged);
        return merged.map((m) => m.toEntity()).toList();
      } on PetRemoteException catch (e) {
        debugPrint('PetRepository: Remote error (${e.statusCode}): ${e.message}');
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

  @override
  Future<Pet> addPet(Pet pet) async {
    final model = PetModel.fromEntity(pet);
    final saved = await _localDataSource.addPet(model);
    if (remoteDataSource != null && token != null && token!.isNotEmpty) {
      try {
        await remoteDataSource!.createPet(model, token!);
      } catch (e) {
        debugPrint('PetRepository: Failed to save pet to server: $e');
      }
    }
    return saved.toEntity();
  }

  @override
  Future<Pet> updatePet(Pet pet) async {
    final model = PetModel.fromEntity(pet);
    final saved = await _localDataSource.updatePet(model);
    if (remoteDataSource != null && token != null && token!.isNotEmpty) {
      try {
        await remoteDataSource!.updatePet(model, token!);
      } catch (e) {
        debugPrint('PetRepository: Failed to update pet on server: $e');
      }
    }
    return saved.toEntity();
  }

  @override
  Future<void> deletePet(String id) async {
    await _localDataSource.deletePet(id);
    if (remoteDataSource != null && token != null && token!.isNotEmpty) {
      try {
        await remoteDataSource!.deletePet(id, token!);
      } catch (e) {
        debugPrint('PetRepository: Failed to delete pet from server: $e');
      }
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
