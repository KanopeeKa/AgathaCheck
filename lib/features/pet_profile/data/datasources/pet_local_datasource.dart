import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/constants.dart';
import '../models/pet_model.dart';

/// Local data source for pet profile storage using SharedPreferences.
///
/// Handles all CRUD operations against the local key-value store.
/// Pet data is stored as a JSON-encoded list of pet objects.
abstract class PetLocalDataSource {
  /// Retrieves all pet models from local storage.
  Future<List<PetModel>> getAllPets();

  /// Retrieves a single pet model by [id].
  Future<PetModel?> getPetById(String id);

  /// Saves a new pet model to local storage.
  Future<PetModel> addPet(PetModel pet);

  /// Updates an existing pet model in local storage.
  Future<PetModel> updatePet(PetModel pet);

  /// Deletes a pet model by [id] from local storage.
  Future<void> deletePet(String id);
}

/// Implementation of [PetLocalDataSource] backed by SharedPreferences.
class PetLocalDataSourceImpl implements PetLocalDataSource {
  /// Creates a [PetLocalDataSourceImpl] with the given [SharedPreferences].
  PetLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  List<PetModel> _loadPets() {
    final jsonString = _prefs.getString(AppConstants.petsStorageKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    final list = json.decode(jsonString) as List<dynamic>;
    return list
        .map((e) => PetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _savePets(List<PetModel> pets) async {
    final jsonString = json.encode(pets.map((p) => p.toJson()).toList());
    await _prefs.setString(AppConstants.petsStorageKey, jsonString);
  }

  @override
  Future<List<PetModel>> getAllPets() async => _loadPets();

  @override
  Future<PetModel?> getPetById(String id) async {
    final pets = _loadPets();
    try {
      return pets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PetModel> addPet(PetModel pet) async {
    final pets = _loadPets();
    pets.add(pet);
    await _savePets(pets);
    return pet;
  }

  @override
  Future<PetModel> updatePet(PetModel pet) async {
    final pets = _loadPets();
    final index = pets.indexWhere((p) => p.id == pet.id);
    if (index == -1) throw Exception('Pet not found: ${pet.id}');
    pets[index] = pet;
    await _savePets(pets);
    return pet;
  }

  @override
  Future<void> deletePet(String id) async {
    final pets = _loadPets();
    pets.removeWhere((p) => p.id == id);
    await _savePets(pets);
  }
}
