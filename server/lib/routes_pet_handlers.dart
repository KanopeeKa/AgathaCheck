import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import 'calendar_date.dart';
import 'http_security.dart';
import 'routes_common.dart';
import 'routes_pool.dart';

final _uuid = Uuid();

Future<Response> getAllPets(Request request) async {
  final userId = extractUserId(request);
  if (userId == null) {
    return Response(401,
        body: jsonEncode({'error': 'Unauthorized'}), headers: jsonHeaders);
  }
  try {
    final results = await pool.execute(
      Sql.named(
          'SELECT * FROM pets WHERE user_id = @userId ORDER BY created_at'),
      parameters: {'userId': userId},
    );
    final pets = results.map(petRowToMap).toList();
    await autoAssignColors(pets);
    return Response.ok(jsonEncode(pets), headers: jsonHeaders);
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'error': publicError(e, 'Error fetching all pets')}),
        headers: jsonHeaders);
  }
}

Future<Response> getPets(Request request) async {
  final userId = extractUserId(request);
  if (userId == null) {
    return Response(401,
        body: jsonEncode({'error': 'Unauthorized'}), headers: jsonHeaders);
  }
  try {
    final results = await pool.execute(
      Sql.named(
          'SELECT * FROM pets WHERE user_id = @userId ORDER BY created_at'),
      parameters: {'userId': userId},
    );
    final pets = results.map(petRowToMap).toList();
    await autoAssignColors(pets);
    return Response.ok(jsonEncode(pets), headers: jsonHeaders);
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'error': publicError(e, 'Error fetching pets')}),
        headers: jsonHeaders);
  }
}

Future<Response> getPetById(Request request, String id) async {
  final userId = extractUserId(request);
  if (userId == null) {
    return Response(401,
        body: jsonEncode({'error': 'Unauthorized'}), headers: jsonHeaders);
  }
  try {
    final results = await pool.execute(
      Sql.named('SELECT * FROM pets WHERE id = @id AND user_id = @userId'),
      parameters: {'id': id, 'userId': userId},
    );
    if (results.isEmpty) {
      return Response.notFound(jsonEncode({'error': 'Pet not found'}),
          headers: jsonHeaders);
    }
    return Response.ok(jsonEncode(petRowToMap(results.first)),
        headers: jsonHeaders);
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'error': publicError(e, 'Error fetching pet')}),
        headers: jsonHeaders);
  }
}

Future<Response> createPet(Request request) async {
  final userId = extractUserId(request);
  if (userId == null) {
    return Response(401,
        body: jsonEncode({'error': 'Unauthorized'}), headers: jsonHeaders);
  }
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final id = data['id'] ?? _uuid.v4();
    final orgId = data['organization_id'];
    if (orgId != null &&
        orgId.toString().isNotEmpty &&
        !(await userInOrg(orgId, userId))) {
      return Response(403,
          body: jsonEncode({'error': 'Not a member of this organization'}),
          headers: jsonHeaders);
    }
    final dobStr = data['dateOfBirth'] ?? data['date_of_birth'];
    final neuteredStr = data['neuteredDate'];
    final results = await pool.execute(
      Sql.named(
          'INSERT INTO pets (id, user_id, name, species, breed, age, date_of_birth, weight, gender, bio, insurance, neutered_date, neuter_dismissed, chip_id, chip_dismissed, photo_path, vet_id, color_index, passed_away, organization_id) VALUES (@id, @user_id, @name, @species, @breed, @age, @dob, @weight, @gender, @bio, @insurance, @neutered_date, @neuter_dismissed, @chip_id, @chip_dismissed, @photo_path, @vet_id, @color_index, @passed_away, @organization_id) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, species = EXCLUDED.species, breed = EXCLUDED.breed, age = EXCLUDED.age, date_of_birth = EXCLUDED.date_of_birth, weight = EXCLUDED.weight, gender = EXCLUDED.gender, bio = EXCLUDED.bio, insurance = EXCLUDED.insurance, neutered_date = EXCLUDED.neutered_date, neuter_dismissed = EXCLUDED.neuter_dismissed, chip_id = EXCLUDED.chip_id, chip_dismissed = EXCLUDED.chip_dismissed, photo_path = EXCLUDED.photo_path, vet_id = EXCLUDED.vet_id, color_index = EXCLUDED.color_index, passed_away = EXCLUDED.passed_away, organization_id = EXCLUDED.organization_id, updated_at = NOW() WHERE pets.user_id = @user_id RETURNING *'),
      parameters: {
        'id': id,
        'user_id': userId,
        'name': data['name'],
        'species': data['species'],
        'breed': data['breed'] ?? '',
        'age': data['age'],
        'dob': dateToIsoDate(dobStr),
        'weight': data['weight'],
        'gender': data['gender'],
        'bio': data['bio'] ?? '',
        'insurance': data['insurance'] ?? '',
        'neutered_date': dateToIsoDate(neuteredStr),
        'neuter_dismissed': data['neuterDismissed'] ?? false,
        'chip_id': data['chipId'] ?? '',
        'chip_dismissed': data['chipDismissed'] ?? false,
        'photo_path': data['photoPath'],
        'vet_id': data['vetId'],
        'color_index': data['colorValue'],
        'passed_away': data['passedAway'] ?? false,
        'organization_id': data['organization_id'],
      },
    );
    return Response(201,
        body: jsonEncode(petRowToMap(results.first)), headers: jsonHeaders);
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'error': publicError(e, 'Error creating pet')}),
        headers: jsonHeaders);
  }
}

Future<Response> updatePet(Request request, String id) async {
  final userId = extractUserId(request);
  if (userId == null) {
    return Response(401,
        body: jsonEncode({'error': 'Unauthorized'}), headers: jsonHeaders);
  }
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final orgId = data['organization_id'];
    if (orgId != null &&
        orgId.toString().isNotEmpty &&
        !(await userInOrg(orgId, userId))) {
      return Response(403,
          body: jsonEncode({'error': 'Not a member of this organization'}),
          headers: jsonHeaders);
    }
    final dobStr = data['dateOfBirth'] ?? data['date_of_birth'];
    final neuteredStr = data['neuteredDate'];
    final results = await pool.execute(
      Sql.named(
          'UPDATE pets SET name = @name, species = @species, breed = @breed, age = @age, date_of_birth = @dob, weight = @weight, gender = @gender, bio = @bio, insurance = @insurance, neutered_date = @neutered_date, neuter_dismissed = @neuter_dismissed, chip_id = @chip_id, chip_dismissed = @chip_dismissed, photo_path = @photo_path, vet_id = @vet_id, color_index = @color_index, passed_away = @passed_away, organization_id = @organization_id, updated_at = NOW() WHERE id = @id AND user_id = @userId RETURNING *'),
      parameters: {
        'id': id,
        'userId': userId,
        'name': data['name'],
        'species': data['species'],
        'breed': data['breed'] ?? '',
        'age': data['age'],
        'dob': dateToIsoDate(dobStr),
        'weight': data['weight'],
        'gender': data['gender'],
        'bio': data['bio'] ?? '',
        'insurance': data['insurance'] ?? '',
        'neutered_date': dateToIsoDate(neuteredStr),
        'neuter_dismissed': data['neuterDismissed'] ?? false,
        'chip_id': data['chipId'] ?? '',
        'chip_dismissed': data['chipDismissed'] ?? false,
        'photo_path': data['photoPath'],
        'vet_id': data['vetId'],
        'color_index': data['colorValue'],
        'passed_away': data['passedAway'] ?? false,
        'organization_id': data['organization_id'],
      },
    );
    if (results.isEmpty) {
      return Response.notFound(jsonEncode({'error': 'Pet not found'}),
          headers: jsonHeaders);
    }
    return Response.ok(jsonEncode(petRowToMap(results.first)),
        headers: jsonHeaders);
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'error': publicError(e, 'Error updating pet')}),
        headers: jsonHeaders);
  }
}

Future<Response> deletePet(Request request, String id) async {
  final userId = extractUserId(request);
  if (userId == null) {
    return Response(401,
        body: jsonEncode({'error': 'Unauthorized'}), headers: jsonHeaders);
  }
  try {
    await pool.execute(
      Sql.named('DELETE FROM pets WHERE id = @id AND user_id = @userId'),
      parameters: {'id': id, 'userId': userId},
    );
    return Response.ok(jsonEncode({'deleted': true}), headers: jsonHeaders);
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'error': publicError(e, 'Error deleting pet')}),
        headers: jsonHeaders);
  }
}

Future<Response> transferPetToOrg(Request request, String id) async {
  return notImplemented();
}

Future<Response> getFamilyEvents(Request request, String id) async {
  return Response.ok(jsonEncode([]), headers: jsonHeaders);
}

Future<Response> createFamilyEvent(Request request, String id) async {
  return notImplemented();
}

Future<Response> updateFamilyEvent(
    Request request, String id, String eventId) async {
  return notImplemented();
}

Future<Response> deleteFamilyEvent(
    Request request, String id, String eventId) async {
  return notImplemented();
}

Future<Response> getPetAccess(Request request, String id) async {
  return Response.ok(jsonEncode([]), headers: jsonHeaders);
}

Future<Response> updatePetAccessRole(
    Request request, String id, String userId) async {
  return notImplemented();
}

Future<Response> deletePetAccess(
    Request request, String id, String userId) async {
  return notImplemented();
}

Future<Response> deletePetData(Request request, String id) async {
  return Response.ok(jsonEncode({'deleted': true, 'pet_id': id}),
      headers: jsonHeaders);
}

Future<Response> markPetPassedAway(Request request, String id) async {
  return Response.ok(jsonEncode({'passed_away': true, 'pet_id': id}),
      headers: jsonHeaders);
}
