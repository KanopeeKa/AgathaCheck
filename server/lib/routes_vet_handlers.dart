import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import 'http_security.dart';
import 'routes_common.dart';
import 'routes_pool.dart';

final _uuid = Uuid();

Future<Response> getVets(Request request) async {
  final userId = extractUserId(request);
  if (userId == null) {
    return Response(401,
        body: jsonEncode({'error': 'Unauthorized'}), headers: jsonHeaders);
  }
  try {
    final results = await pool.execute(
      Sql.named('SELECT * FROM vets WHERE user_id = @userId ORDER BY name'),
      parameters: {'userId': userId},
    );
    return Response.ok(jsonEncode(results.map(vetRowToMap).toList()),
        headers: jsonHeaders);
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'error': publicError(e)}));
  }
}

Future<Response> getVetById(Request request, String id) async {
  final userId = extractUserId(request);
  if (userId == null) {
    return Response(401,
        body: jsonEncode({'error': 'Unauthorized'}), headers: jsonHeaders);
  }
  try {
    final results = await pool.execute(
      Sql.named('SELECT * FROM vets WHERE id = @id AND user_id = @userId'),
      parameters: {'id': id, 'userId': userId},
    );
    if (results.isEmpty) {
      return Response.notFound(jsonEncode({'error': 'Vet not found'}));
    }
    return Response.ok(jsonEncode(vetRowToMap(results.first)),
        headers: jsonHeaders);
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'error': publicError(e)}));
  }
}

Future<Response> createVet(Request request) async {
  final userId = extractUserId(request);
  if (userId == null) {
    return Response(401,
        body: jsonEncode({'error': 'Unauthorized'}), headers: jsonHeaders);
  }
  try {
    final body = jsonDecode(await request.readAsString());
    final id = _uuid.v4();
    final results = await pool.execute(
      Sql.named(
          'INSERT INTO vets (id, user_id, name, clinic, phone, email, website, address, notes) VALUES (@id, @userId, @name, @clinic, @phone, @email, @website, @address, @notes) RETURNING *'),
      parameters: {
        'id': id,
        'userId': userId,
        'name': body['name'] ?? '',
        'clinic': body['clinic'],
        'phone': body['phone'],
        'email': body['email'],
        'website': body['website'] ?? '',
        'address': body['address'] ?? '',
        'notes': body['notes'] ?? '',
      },
    );
    return Response(201,
        body: jsonEncode(vetRowToMap(results.first)), headers: jsonHeaders);
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'error': publicError(e)}));
  }
}

Future<Response> updateVet(Request request, String id) async {
  final userId = extractUserId(request);
  if (userId == null) {
    return Response(401,
        body: jsonEncode({'error': 'Unauthorized'}), headers: jsonHeaders);
  }
  try {
    final body = jsonDecode(await request.readAsString());
    final results = await pool.execute(
      Sql.named(
          'UPDATE vets SET name = @name, clinic = @clinic, phone = @phone, email = @email, website = @website, address = @address, notes = @notes, updated_at = NOW() WHERE id = @id AND user_id = @userId RETURNING *'),
      parameters: {
        'name': body['name'],
        'clinic': body['clinic'],
        'phone': body['phone'],
        'email': body['email'],
        'website': body['website'] ?? '',
        'address': body['address'] ?? '',
        'notes': body['notes'] ?? '',
        'id': id,
        'userId': userId,
      },
    );
    if (results.isEmpty) {
      return Response.notFound(jsonEncode({'error': 'Vet not found'}));
    }
    return Response.ok(jsonEncode(vetRowToMap(results.first)),
        headers: jsonHeaders);
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'error': publicError(e)}));
  }
}

Future<Response> deleteVet(Request request, String id) async {
  final userId = extractUserId(request);
  if (userId == null) {
    return Response(401,
        body: jsonEncode({'error': 'Unauthorized'}), headers: jsonHeaders);
  }
  try {
    final results = await pool.execute(
      Sql.named(
          'DELETE FROM vets WHERE id = @id AND user_id = @userId RETURNING *'),
      parameters: {'id': id, 'userId': userId},
    );
    if (results.isEmpty) {
      return Response.notFound(jsonEncode({'error': 'Vet not found'}));
    }
    return Response.ok(jsonEncode({'message': 'Vet deleted'}),
        headers: jsonHeaders);
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'error': publicError(e)}));
  }
}
