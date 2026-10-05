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

  /// UTC timestamp of the last successful remote pet-list sync for this user scope.
  Future<DateTime?> getLastSyncedAt();

  /// Persists [utc] as the last successful remote pet-list sync for this user scope.
  Future<void> setLastSyncedAt(DateTime utc);

  /// Clears pets and sync metadata for this user scope (logout / user switch).
  Future<void> clearCache();
}

/// Implementation of [PetLocalDataSource] backed by SharedPreferences.
class PetLocalDataSourceImpl implements PetLocalDataSource {
  /// Creates a [PetLocalDataSourceImpl] with the given [SharedPreferences].
  PetLocalDataSourceImpl(this._prefs, {this.userId});

  final SharedPreferences _prefs;
  final String? userId;

  String get _storageKey => userId != null && userId!.isNotEmpty
      ? '${AppConstants.petsStorageKey}_$userId'
      : AppConstants.petsStorageKey;

  String get _lastSyncedKey => userId != null && userId!.isNotEmpty
      ? '${AppConstants.petsStorageKey}_last_synced_$userId'
      : '${AppConstants.petsStorageKey}_last_synced';

  bool _migrated = false;

  void _migrateIfNeeded() {
    if (_migrated) return;
    _migrated = true;
    if (userId == null || userId!.isEmpty) return;
    final userKey = _storageKey;
    final existing = _prefs.getString(userKey);
    if (existing != null && existing.isNotEmpty) return;
    final oldData = _prefs.getString(AppConstants.petsStorageKey);
    if (oldData != null && oldData.isNotEmpty) {
      _prefs.setString(userKey, oldData);
      _prefs.remove(AppConstants.petsStorageKey);
    }
  }

  List<PetModel> _loadPets() {
    _migrateIfNeeded();
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    final list = json.decode(jsonString) as List<dynamic>;
    return list
        .map((e) => PetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _savePets(List<PetModel> pets) async {
    final jsonString = json.encode(pets.map((p) => p.toJson()).toList());
    await _prefs.setString(_storageKey, jsonString);
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

  @override
  Future<DateTime?> getLastSyncedAt() async {
    _migrateIfNeeded();
    final raw = _prefs.getString(_lastSyncedKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.parse(raw).toUtc();
  }

  @override
  Future<void> setLastSyncedAt(DateTime utc) async {
    _migrateIfNeeded();
    await _prefs.setString(_lastSyncedKey, utc.toUtc().toIso8601String());
  }

  @override
  Future<void> clearCache() async {
    _migrateIfNeeded();
    await _prefs.remove(_storageKey);
    await _prefs.remove(_lastSyncedKey);
  }
}
