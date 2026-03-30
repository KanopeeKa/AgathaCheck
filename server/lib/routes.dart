import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

late Pool _pool;
Pool get pool => _pool;

Future<void> initPool() async {
  final databaseUrl = Platform.environment['DATABASE_URL'] ??
      'postgresql://user:password@localhost:5432/agatha_db';
  final uri = Uri.parse(databaseUrl);
  final host = uri.host.isNotEmpty ? uri.host : (Platform.environment['PGHOST'] ?? 'localhost');
  final port = uri.port > 0 ? uri.port : int.parse(Platform.environment['PGPORT'] ?? '5432');
  final dbName = uri.pathSegments.isNotEmpty
      ? uri.pathSegments.first
      : (Platform.environment['PGDATABASE'] ?? 'agatha_db');
  final userInfo = uri.userInfo.isNotEmpty ? uri.userInfo : '';
  final username = userInfo.contains(':')
      ? userInfo.split(':').first
      : (Platform.environment['PGUSER'] ?? 'user');
  final password = userInfo.contains(':')
      ? userInfo.split(':').last
      : (Platform.environment['PGPASSWORD'] ?? 'password');

  final endpoint = Endpoint(
    host: host,
    port: port,
    database: dbName,
    username: username,
    password: password,
  );

  final sslMode = uri.scheme == 'postgresqls' ? SslMode.require : SslMode.disable;

  _pool = Pool.withEndpoints(
    [endpoint],
    settings: PoolSettings(
      maxConnectionCount: 10,
      sslMode: sslMode,
    ),
  );
}

Router apiHandler() {
  final app = Router();

  app.get('/pets', _getPets);
  app.get('/pets/all', _getAllPets);
  app.get('/pets/<id|[0-9a-fA-F\\-]{36}>', _getPetById);
  app.post('/pets', _createPet);
  app.put('/pets/<id|[0-9a-fA-F\\-]{36}>', _updatePet);
  app.delete('/pets/<id|[0-9a-fA-F\\-]{36}>', _deletePet);
  app.post('/pets/<id|[0-9a-fA-F\\-]{36}>/transfer-to-org', _transferPetToOrg);
  app.get('/pets/<id|[0-9a-fA-F\\-]{36}>/family-events', _getFamilyEvents);
  app.post('/pets/<id|[0-9a-fA-F\\-]{36}>/family-events', _createFamilyEvent);
  app.put('/pets/<id|[0-9a-fA-F\\-]{36}>/family-events/<eventId|[0-9]+>', _updateFamilyEvent);
  app.delete('/pets/<id|[0-9a-fA-F\\-]{36}>/family-events/<eventId|[0-9]+>', _deleteFamilyEvent);
  app.get('/pets/<id|[0-9a-fA-F\\-]{36}>/access', _getPetAccess);
  app.put('/pets/<id|[0-9a-fA-F\\-]{36}>/access/<userId|[0-9]+>/role', _updatePetAccessRole);
  app.delete('/pets/<id|[0-9a-fA-F\\-]{36}>/access/<userId|[0-9]+>', _deletePetAccess);
  app.delete('/pets/<id|[0-9a-fA-F\\-]{36}>/data', _deletePetData);
  app.post('/pets/<id|[0-9a-fA-F\\-]{36}>/passed-away', _markPetPassedAway);
  app.get('/health', (req) => Response.ok('OK'));

  return app;
}

const _jsonHeaders = {'Content-Type': 'application/json'};

Map<String, dynamic> _petRowToMap(ResultRow row) {
  final columns = row.toColumnMap();
  return {
    'id': columns['id']?.toString(),
    'user_id': columns['user_id']?.toString(),
    'name': columns['name'],
    'species': columns['species'],
    'breed': columns['breed'],
    'age': columns['age'],
    'date_of_birth': columns['date_of_birth']?.toString(),
    'weight': columns['weight'],
    'gender': columns['gender'],
    'photo_path': columns['photo_path'],
    'color_index': columns['color_index'],
    'identification': columns['identification'],
    'vet_id': columns['vet_id'],
    'passed_away': columns['passed_away'],
    'organization_id': columns['organization_id'],
    'created_at': columns['created_at']?.toString(),
    'updated_at': columns['updated_at']?.toString(),
  };
}

Future<Response> _getAllPets(Request request) async {
  try {
    final results = await _pool.execute(Sql('SELECT * FROM pets ORDER BY created_at'));
    final pets = results.map(_petRowToMap).toList();
    return Response.ok(jsonEncode(pets), headers: _jsonHeaders);
  } catch (e) {
    return Response.internalServerError(body: jsonEncode({'error': 'Error fetching all pets: $e'}), headers: _jsonHeaders);
  }
}

Future<Response> _getPets(Request request) async {
  try {
    final results = await _pool.execute(Sql('SELECT * FROM pets ORDER BY created_at'));
    final pets = results.map(_petRowToMap).toList();
    return Response.ok(jsonEncode(pets), headers: _jsonHeaders);
  } catch (e) {
    return Response.internalServerError(body: jsonEncode({'error': 'Error fetching pets: $e'}), headers: _jsonHeaders);
  }
}

Future<Response> _getPetById(Request request, String id) async {
  try {
    final results = await _pool.execute(
      Sql.named('SELECT * FROM pets WHERE id = @id'),
      parameters: {'id': id},
    );
    if (results.isEmpty) {
      return Response.notFound(jsonEncode({'error': 'Pet not found'}), headers: _jsonHeaders);
    }
    return Response.ok(jsonEncode(_petRowToMap(results.first)), headers: _jsonHeaders);
  } catch (e) {
    return Response.internalServerError(body: jsonEncode({'error': 'Error fetching pet: $e'}), headers: _jsonHeaders);
  }
}

Future<Response> _createPet(Request request) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final id = _uuid.v4();
    await _pool.execute(
      Sql.named('INSERT INTO pets (id, user_id, name, species, breed, age, date_of_birth, weight, gender) VALUES (@id, @user_id, @name, @species, @breed, @age, @date_of_birth, @weight, @gender)'),
      parameters: {
        'id': id,
        'user_id': data['user_id'],
        'name': data['name'],
        'species': data['species'],
        'breed': data['breed'] ?? '',
        'age': data['age'],
        'date_of_birth': data['date_of_birth'] != null ? DateTime.parse(data['date_of_birth'].toString()) : null,
        'weight': data['weight'],
        'gender': data['gender'],
      },
    );
    return Response.ok(jsonEncode({'id': id}), headers: _jsonHeaders);
  } catch (e) {
    return Response.internalServerError(body: jsonEncode({'error': 'Error creating pet: $e'}), headers: _jsonHeaders);
  }
}

Future<Response> _updatePet(Request request, String id) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    await _pool.execute(
      Sql.named('UPDATE pets SET name = @name, species = @species, breed = @breed, age = @age, date_of_birth = @date_of_birth, weight = @weight, gender = @gender, updated_at = NOW() WHERE id = @id'),
      parameters: {
        'id': id,
        'name': data['name'],
        'species': data['species'],
        'breed': data['breed'] ?? '',
        'age': data['age'],
        'date_of_birth': data['date_of_birth'] != null ? DateTime.parse(data['date_of_birth'].toString()) : null,
        'weight': data['weight'],
        'gender': data['gender'],
      },
    );
    return Response.ok(jsonEncode({'updated': true}), headers: _jsonHeaders);
  } catch (e) {
    return Response.internalServerError(body: jsonEncode({'error': 'Error updating pet: $e'}), headers: _jsonHeaders);
  }
}

Future<Response> _deletePet(Request request, String id) async {
  try {
    await _pool.execute(
      Sql.named('DELETE FROM pets WHERE id = @id'),
      parameters: {'id': id},
    );
    return Response.ok(jsonEncode({'deleted': true}), headers: _jsonHeaders);
  } catch (e) {
    return Response.internalServerError(body: jsonEncode({'error': 'Error deleting pet: $e'}), headers: _jsonHeaders);
  }
}

Future<Response> _transferPetToOrg(Request request, String id) async {
  return Response.ok(jsonEncode({'status': 'transferred', 'pet_id': id}), headers: _jsonHeaders);
}

Future<Response> _getFamilyEvents(Request request, String id) async {
  return Response.ok(jsonEncode([]), headers: _jsonHeaders);
}

Future<Response> _createFamilyEvent(Request request, String id) async {
  return Response.ok(jsonEncode({'event_id': 1}), headers: _jsonHeaders);
}

Future<Response> _updateFamilyEvent(Request request, String id, String eventId) async {
  return Response.ok(jsonEncode({'updated': true, 'event_id': eventId}), headers: _jsonHeaders);
}

Future<Response> _deleteFamilyEvent(Request request, String id, String eventId) async {
  return Response.ok(jsonEncode({'deleted': true, 'event_id': eventId}), headers: _jsonHeaders);
}

Future<Response> _getPetAccess(Request request, String id) async {
  return Response.ok(jsonEncode([]), headers: _jsonHeaders);
}

Future<Response> _updatePetAccessRole(Request request, String id, String userId) async {
  return Response.ok(jsonEncode({'updated': true, 'user_id': userId}), headers: _jsonHeaders);
}

Future<Response> _deletePetAccess(Request request, String id, String userId) async {
  return Response.ok(jsonEncode({'deleted': true, 'user_id': userId}), headers: _jsonHeaders);
}

Future<Response> _deletePetData(Request request, String id) async {
  return Response.ok(jsonEncode({'deleted': true, 'pet_id': id}), headers: _jsonHeaders);
}

Future<Response> _markPetPassedAway(Request request, String id) async {
  return Response.ok(jsonEncode({'passed_away': true, 'pet_id': id}), headers: _jsonHeaders);
}
