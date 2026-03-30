import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

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

  app.get('/vets', _getVets);
  app.get('/vets/<id|[0-9a-fA-F\\-]{36}>', _getVetById);
  app.post('/vets', _createVet);
  app.put('/vets/<id|[0-9a-fA-F\\-]{36}>', _updateVet);
  app.delete('/vets/<id|[0-9a-fA-F\\-]{36}>', _deleteVet);

  return app;
}

const _jsonHeaders = {'Content-Type': 'application/json'};

Map<String, dynamic> _petRowToMap(ResultRow row) {
  final c = row.toColumnMap();
  return {
    'id': c['id']?.toString(),
    'user_id': c['user_id']?.toString(),
    'name': c['name'],
    'species': c['species'],
    'breed': c['breed'] ?? '',
    'age': c['age'],
    'dateOfBirth': c['date_of_birth']?.toString(),
    'date_of_birth': c['date_of_birth']?.toString(),
    'weight': c['weight'],
    'gender': c['gender'],
    'bio': c['bio'] ?? '',
    'insurance': c['insurance'] ?? '',
    'neuteredDate': c['neutered_date']?.toString(),
    'neuterDismissed': c['neuter_dismissed'] ?? false,
    'chipId': c['chip_id'] ?? '',
    'chipDismissed': c['chip_dismissed'] ?? false,
    'photoPath': c['photo_path'],
    'vetId': c['vet_id']?.toString(),
    'colorValue': c['color_index'],
    'passedAway': c['passed_away'] ?? false,
    'organization_id': c['organization_id'],
    'created_at': c['created_at']?.toString(),
    'updated_at': c['updated_at']?.toString(),
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
    final id = data['id'] ?? _uuid.v4();
    final userId = _extractUserId(request) ?? data['user_id'];
    final dobStr = data['dateOfBirth'] ?? data['date_of_birth'];
    final neuteredStr = data['neuteredDate'];
    final results = await _pool.execute(
      Sql.named('INSERT INTO pets (id, user_id, name, species, breed, age, date_of_birth, weight, gender, bio, insurance, neutered_date, neuter_dismissed, chip_id, chip_dismissed, photo_path, vet_id, color_index, passed_away, organization_id) VALUES (@id, @user_id, @name, @species, @breed, @age, @dob, @weight, @gender, @bio, @insurance, @neutered_date, @neuter_dismissed, @chip_id, @chip_dismissed, @photo_path, @vet_id, @color_index, @passed_away, @organization_id) RETURNING *'),
      parameters: {
        'id': id,
        'user_id': userId,
        'name': data['name'],
        'species': data['species'],
        'breed': data['breed'] ?? '',
        'age': data['age'],
        'dob': dobStr != null ? DateTime.parse(dobStr.toString()) : null,
        'weight': data['weight'],
        'gender': data['gender'],
        'bio': data['bio'] ?? '',
        'insurance': data['insurance'] ?? '',
        'neutered_date': neuteredStr != null ? DateTime.parse(neuteredStr.toString()) : null,
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
    return Response(201, body: jsonEncode(_petRowToMap(results.first)), headers: _jsonHeaders);
  } catch (e) {
    return Response.internalServerError(body: jsonEncode({'error': 'Error creating pet: $e'}), headers: _jsonHeaders);
  }
}

Future<Response> _updatePet(Request request, String id) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final dobStr = data['dateOfBirth'] ?? data['date_of_birth'];
    final neuteredStr = data['neuteredDate'];
    final results = await _pool.execute(
      Sql.named('UPDATE pets SET name = @name, species = @species, breed = @breed, age = @age, date_of_birth = @dob, weight = @weight, gender = @gender, bio = @bio, insurance = @insurance, neutered_date = @neutered_date, neuter_dismissed = @neuter_dismissed, chip_id = @chip_id, chip_dismissed = @chip_dismissed, photo_path = @photo_path, vet_id = @vet_id, color_index = @color_index, passed_away = @passed_away, organization_id = @organization_id, updated_at = NOW() WHERE id = @id RETURNING *'),
      parameters: {
        'id': id,
        'name': data['name'],
        'species': data['species'],
        'breed': data['breed'] ?? '',
        'age': data['age'],
        'dob': dobStr != null ? DateTime.parse(dobStr.toString()) : null,
        'weight': data['weight'],
        'gender': data['gender'],
        'bio': data['bio'] ?? '',
        'insurance': data['insurance'] ?? '',
        'neutered_date': neuteredStr != null ? DateTime.parse(neuteredStr.toString()) : null,
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
      return Response.notFound(jsonEncode({'error': 'Pet not found'}), headers: _jsonHeaders);
    }
    return Response.ok(jsonEncode(_petRowToMap(results.first)), headers: _jsonHeaders);
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

final _jwtSecret = Platform.environment['JWT_SECRET'] ??
    Platform.environment['SESSION_SECRET'] ??
    'default_secret';

String? _extractUserId(Request request) {
  final auth =
      request.headers['authorization'] ?? request.headers['Authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) return null;
  try {
    final jwt = JWT.verify(auth.substring(7), SecretKey(_jwtSecret));
    return (jwt.payload as Map)['id']?.toString();
  } catch (_) {
    return null;
  }
}

Map<String, dynamic> _vetRowToMap(ResultRow row) {
  final c = row.toColumnMap();
  return {
    'id': c['id']?.toString(),
    'user_id': c['user_id']?.toString(),
    'name': c['name'],
    'clinic': c['clinic'],
    'phone': c['phone'],
    'email': c['email'],
    'created_at': c['created_at']?.toString(),
    'updated_at': c['updated_at']?.toString(),
  };
}

Future<Response> _getVets(Request request) async {
  final userId = _extractUserId(request);
  if (userId == null) {
    return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
  }
  try {
    final results = await _pool.execute(
      Sql.named('SELECT * FROM vets WHERE user_id = @userId ORDER BY name'),
      parameters: {'userId': userId},
    );
    return Response.ok(jsonEncode(results.map(_vetRowToMap).toList()), headers: _jsonHeaders);
  } catch (e) {
    return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
  }
}

Future<Response> _getVetById(Request request, String id) async {
  final userId = _extractUserId(request);
  if (userId == null) {
    return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
  }
  try {
    final results = await _pool.execute(
      Sql.named('SELECT * FROM vets WHERE id = @id AND user_id = @userId'),
      parameters: {'id': id, 'userId': userId},
    );
    if (results.isEmpty) return Response.notFound(jsonEncode({'error': 'Vet not found'}));
    return Response.ok(jsonEncode(_vetRowToMap(results.first)), headers: _jsonHeaders);
  } catch (e) {
    return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
  }
}

Future<Response> _createVet(Request request) async {
  final userId = _extractUserId(request);
  if (userId == null) {
    return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
  }
  try {
    final body = jsonDecode(await request.readAsString());
    final id = _uuid.v4();
    final results = await _pool.execute(
      Sql.named(
          'INSERT INTO vets (id, user_id, name, clinic, phone, email) VALUES (@id, @userId, @name, @clinic, @phone, @email) RETURNING *'),
      parameters: {
        'id': id,
        'userId': userId,
        'name': body['name'] ?? '',
        'clinic': body['clinic'],
        'phone': body['phone'],
        'email': body['email'],
      },
    );
    return Response(201, body: jsonEncode(_vetRowToMap(results.first)), headers: _jsonHeaders);
  } catch (e) {
    return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
  }
}

Future<Response> _updateVet(Request request, String id) async {
  final userId = _extractUserId(request);
  if (userId == null) {
    return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
  }
  try {
    final body = jsonDecode(await request.readAsString());
    final results = await _pool.execute(
      Sql.named(
          'UPDATE vets SET name = @name, clinic = @clinic, phone = @phone, email = @email, updated_at = NOW() WHERE id = @id AND user_id = @userId RETURNING *'),
      parameters: {
        'name': body['name'],
        'clinic': body['clinic'],
        'phone': body['phone'],
        'email': body['email'],
        'id': id,
        'userId': userId,
      },
    );
    if (results.isEmpty) return Response.notFound(jsonEncode({'error': 'Vet not found'}));
    return Response.ok(jsonEncode(_vetRowToMap(results.first)), headers: _jsonHeaders);
  } catch (e) {
    return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
  }
}

Future<Response> _deleteVet(Request request, String id) async {
  final userId = _extractUserId(request);
  if (userId == null) {
    return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
  }
  try {
    final results = await _pool.execute(
      Sql.named('DELETE FROM vets WHERE id = @id AND user_id = @userId RETURNING *'),
      parameters: {'id': id, 'userId': userId},
    );
    if (results.isEmpty) return Response.notFound(jsonEncode({'error': 'Vet not found'}));
    return Response.ok(jsonEncode({'message': 'Vet deleted'}), headers: _jsonHeaders);
  } catch (e) {
    return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
  }
}
