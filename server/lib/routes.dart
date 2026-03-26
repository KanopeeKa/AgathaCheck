import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

PostgreSQLConnection _getConnection() {
  final databaseUrl = Platform.environment['DATABASE_URL'] ?? 'postgresql://user:password@localhost:5432/agatha_db';
  final uri = Uri.parse(databaseUrl);
  return PostgreSQLConnection(
    uri.host,
    uri.port,
    uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'agatha_db',
    username: uri.userInfo.split(':').first,
    password: uri.userInfo.split(':').last,
    useSSL: uri.scheme == 'postgresqls',
  );
}

Router apiHandler() {
  final app = Router();

  // GET /api/pets - List all pets (personal only)
  app.get('/pets', _getPets);

  // GET /api/pets/all - List all pets (personal + shared + org)
  app.get('/pets/all', _getAllPets);


  // GET /api/pets/{id} (only valid UUIDs)
  app.get('/pets/<id|[0-9a-fA-F\-]{36}>', _getPetById);

  // POST /api/pets - Create pet
  app.post('/pets', _createPet);

  // PUT /api/pets/<id> - Update pet
  app.put('/pets/<id|[0-9a-fA-F\-]{36}>', _updatePet);

  // DELETE /api/pets/<id>
  app.delete('/pets/<id|[0-9a-fA-F\-]{36}>', _deletePet);

  // POST /api/pets/{id}/transfer-to-org
  app.post('/pets/<id|[0-9a-fA-F\-]{36}>/transfer-to-org', _transferPetToOrg);

  // GET /api/pets/{id}/family-events
  app.get('/pets/<id|[0-9a-fA-F\-]{36}>/family-events', _getFamilyEvents);
  // POST /api/pets/{id}/family-events
  app.post('/pets/<id|[0-9a-fA-F\-]{36}>/family-events', _createFamilyEvent);
  // PUT /api/pets/{id}/family-events/{eventId}
  app.put('/pets/<id|[0-9a-fA-F\-]{36}>/family-events/<eventId|[0-9]+>', _updateFamilyEvent);
  // DELETE /api/pets/{id}/family-events/{eventId}
  app.delete('/pets/<id|[0-9a-fA-F\-]{36}>/family-events/<eventId|[0-9]+>', _deleteFamilyEvent);

  // GET /api/pets/{id}/access
  app.get('/pets/<id|[0-9a-fA-F\-]{36}>/access', _getPetAccess);
  // PUT /api/pets/{id}/access/{userId}/role
  app.put('/pets/<id|[0-9a-fA-F\-]{36}>/access/<userId|[0-9]+>/role', _updatePetAccessRole);
  // DELETE /api/pets/{id}/access/{userId}
  app.delete('/pets/<id|[0-9a-fA-F\-]{36}>/access/<userId|[0-9]+>', _deletePetAccess);

  // DELETE /api/pets/{id}/data
  app.delete('/pets/<id|[0-9a-fA-F\-]{36}>/data', _deletePetData);

  // POST /api/pets/{id}/passed-away
  app.post('/pets/<id|[0-9a-fA-F\-]{36}>/passed-away', _markPetPassedAway);
// --- Stub handlers for new endpoints ---
Future<Response> _transferPetToOrg(Request request, String id) async {
  // TODO: Implement DB logic
  return Response.ok(jsonEncode({'status': 'transferred', 'pet_id': id}), headers: {'Content-Type': 'application/json'});
}

Future<Response> _getFamilyEvents(Request request, String id) async {
  // TODO: Implement DB logic
  return Response.ok(jsonEncode([]), headers: {'Content-Type': 'application/json'});
}

Future<Response> _createFamilyEvent(Request request, String id) async {
  // TODO: Implement DB logic
  return Response.ok(jsonEncode({'event_id': 1}), headers: {'Content-Type': 'application/json'});
}

Future<Response> _updateFamilyEvent(Request request, String id, String eventId) async {
  // TODO: Implement DB logic
  return Response.ok(jsonEncode({'updated': true, 'event_id': eventId}), headers: {'Content-Type': 'application/json'});
}

Future<Response> _deleteFamilyEvent(Request request, String id, String eventId) async {
  // TODO: Implement DB logic
  return Response.ok(jsonEncode({'deleted': true, 'event_id': eventId}), headers: {'Content-Type': 'application/json'});
}

Future<Response> _getPetAccess(Request request, String id) async {
  // TODO: Implement DB logic
  return Response.ok(jsonEncode([]), headers: {'Content-Type': 'application/json'});
}

Future<Response> _updatePetAccessRole(Request request, String id, String userId) async {
  // TODO: Implement DB logic
  return Response.ok(jsonEncode({'updated': true, 'user_id': userId}), headers: {'Content-Type': 'application/json'});
}

Future<Response> _deletePetAccess(Request request, String id, String userId) async {
  // TODO: Implement DB logic
  return Response.ok(jsonEncode({'deleted': true, 'user_id': userId}), headers: {'Content-Type': 'application/json'});
}

Future<Response> _deletePetData(Request request, String id) async {
  // TODO: Implement DB logic
  return Response.ok(jsonEncode({'deleted': true, 'pet_id': id}), headers: {'Content-Type': 'application/json'});
}

Future<Response> _markPetPassedAway(Request request, String id) async {
  // TODO: Implement DB logic
  return Response.ok(jsonEncode({'passed_away': true, 'pet_id': id}), headers: {'Content-Type': 'application/json'});
}

  // Health check
  app.get('/health', (req) => Response.ok('OK'));

  return app;
}
// Handler for /api/pets/all
Future<Response> _getAllPets(Request request) async {
  final conn = _getConnection();
  try {
    await conn.open();
    // TODO: Adjust query to include shared/org pets as needed
    final results = await conn.query('SELECT * FROM pets');
    final pets = results.map((row) => {
      'id': row[0],
      'user_id': row[1],
      'name': row[2],
      'species': row[3],
      'breed': row[4],
      'age': row[5],
      'date_of_birth': row[6]?.toIso8601String(),
      'weight': row[7],
      'gender': row[8],
    }).toList();
    await conn.close();
    return Response.ok(jsonEncode(pets), headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(body: 'Error fetching all pets: $e');
  }
}

Future<Response> _getPets(Request request) async {
  final conn = _getConnection();
  try {
    await conn.open();
    final results = await conn.query('SELECT * FROM pets');
    final pets = results.map((row) => {
      'id': row[0],
      'user_id': row[1],
      'name': row[2],
      'species': row[3],
      'breed': row[4],
      'age': row[5],
      'date_of_birth': row[6]?.toIso8601String(),
      'weight': row[7],
      'gender': row[8],
    }).toList();
    await conn.close();
    return Response.ok(jsonEncode(pets), headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(body: 'Error fetching pets: $e');
  }
}

Future<Response> _getPetById(Request request, String id) async {
  final conn = _getConnection();
  try {
    await conn.open();
    final results = await conn.query('SELECT * FROM pets WHERE id = @id', substitutionValues: {'id': id});
    if (results.isEmpty) {
      await conn.close();
      return Response.notFound('Pet not found');
    }
    final row = results.first;
    final pet = {
      'id': row[0],
      'user_id': row[1],
      'name': row[2],
      'species': row[3],
      'breed': row[4],
      'age': row[5],
      'date_of_birth': row[6]?.toIso8601String(),
      'weight': row[7],
      'gender': row[8],
    };
    await conn.close();
    return Response.ok(jsonEncode(pet), headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(body: 'Error fetching pet: $e');
  }
}

Future<Response> _createPet(Request request) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final id = _uuid.v4();
    final conn = _getConnection();
    await conn.open();
    await conn.execute(
      'INSERT INTO pets (id, user_id, name, species, breed, age, date_of_birth, weight, gender) VALUES (@id, @user_id, @name, @species, @breed, @age, @date_of_birth, @weight, @gender)',
      substitutionValues: {
        'id': id,
        'user_id': data['user_id'],
        'name': data['name'],
        'species': data['species'],
        'breed': data['breed'] ?? '',
        'age': data['age'],
        'date_of_birth': data['date_of_birth'] != null ? DateTime.parse(data['date_of_birth']) : null,
        'weight': data['weight'],
        'gender': data['gender'],
      },
    );
    await conn.close();
    return Response.ok(jsonEncode({'id': id}), headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(body: 'Error creating pet: $e');
  }
}

Future<Response> _updatePet(Request request, String id) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final conn = _getConnection();
    await conn.open();
    await conn.execute(
      'UPDATE pets SET name = @name, species = @species, breed = @breed, age = @age, date_of_birth = @date_of_birth, weight = @weight, gender = @gender WHERE id = @id',
      substitutionValues: {
        'id': id,
        'name': data['name'],
        'species': data['species'],
        'breed': data['breed'] ?? '',
        'age': data['age'],
        'date_of_birth': data['date_of_birth'] != null ? DateTime.parse(data['date_of_birth']) : null,
        'weight': data['weight'],
        'gender': data['gender'],
      },
    );
    await conn.close();
    return Response.ok('Pet updated');
  } catch (e) {
    return Response.internalServerError(body: 'Error updating pet: $e');
  }
}

Future<Response> _deletePet(Request request, String id) async {
  final conn = _getConnection();
  try {
    await conn.open();
    await conn.execute('DELETE FROM pets WHERE id = @id', substitutionValues: {'id': id});
    await conn.close();
    return Response.ok('Pet deleted');
  } catch (e) {
    return Response.internalServerError(body: 'Error deleting pet: $e');
  }
}
