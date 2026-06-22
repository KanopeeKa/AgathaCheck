import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'jwt_secret.dart';
import 'http_security.dart';

String? _extractUserId(Request request) {
  final auth = request.headers['authorization'] ?? request.headers['Authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) return null;
  try {
    final jwt = JWT.verify(auth.substring(7), SecretKey(jwtSecret));
    return (jwt.payload as Map)['id']?.toString();
  } catch (_) {
    return null;
  }
}

Router sharingRoutes(Pool pool) {
  final router = Router();

  router.post('/', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) return Response(401, body: jsonEncode({'error': 'Unauthorized'}));
    // NOT IMPLEMENTED (mirrors routes/sharing.js): share-by-code has no
    // persistence, so return 501 instead of a code that can never be resolved.
    return Response(501,
        body: jsonEncode({'error': 'Not implemented'}),
        headers: {'Content-Type': 'application/json'});
  });

  router.get('/pending', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) return Response(401, body: jsonEncode({'error': 'Unauthorized'}));
    try {
      final results = await pool.execute(
        Sql.named("SELECT pa.*, p.name as pet_name FROM pet_access pa JOIN pets p ON p.id = pa.pet_id WHERE pa.user_id = @userId AND pa.role = 'pending_shared'"),
        parameters: {'userId': userId},
      );
      final list = results.map((r) => r.toColumnMap()).toList();
      return Response.ok(jsonEncode(list), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}));
    }
  });

  router.post('/pending/<petId>/accept', (Request request, String petId) async {
    final userId = _extractUserId(request);
    if (userId == null) return Response(401, body: jsonEncode({'error': 'Unauthorized'}));
    try {
      await pool.execute(
        Sql.named("UPDATE pet_access SET role = 'shared' WHERE pet_id = @petId AND user_id = @userId AND role = 'pending_shared'"),
        parameters: {'petId': petId, 'userId': userId},
      );
      return Response.ok(jsonEncode({'message': 'Share accepted'}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}));
    }
  });

  router.post('/pending/<petId>/decline', (Request request, String petId) async {
    final userId = _extractUserId(request);
    if (userId == null) return Response(401, body: jsonEncode({'error': 'Unauthorized'}));
    try {
      await pool.execute(
        Sql.named("DELETE FROM pet_access WHERE pet_id = @petId AND user_id = @userId AND role = 'pending_shared'"),
        parameters: {'petId': petId, 'userId': userId},
      );
      return Response.ok(jsonEncode({'message': 'Share declined'}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}));
    }
  });

  router.put('/<petId>/hide', (Request request, String petId) async {
    final userId = _extractUserId(request);
    if (userId == null) return Response(401, body: jsonEncode({'error': 'Unauthorized'}));
    try {
      final body = jsonDecode(await request.readAsString());
      final hidden = body['hidden'] == true;
      await pool.execute(
        Sql.named('UPDATE pet_access SET hidden = @hidden WHERE pet_id = @petId AND user_id = @userId'),
        parameters: {'hidden': hidden, 'petId': petId, 'userId': userId},
      );
      return Response.ok(
          jsonEncode({'message': hidden ? 'Pet hidden' : 'Pet unhidden'}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}));
    }
  });

  router.get('/hidden', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) return Response(401, body: jsonEncode({'error': 'Unauthorized'}));
    try {
      final results = await pool.execute(
        Sql.named('SELECT pa.*, p.name as pet_name FROM pet_access pa JOIN pets p ON p.id = pa.pet_id WHERE pa.user_id = @userId AND pa.hidden = true'),
        parameters: {'userId': userId},
      );
      final list = results.map((r) => r.toColumnMap()).toList();
      return Response.ok(jsonEncode(list), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}));
    }
  });

  router.get('/<code>', (Request request, String code) async {
    // NOT IMPLEMENTED: share-by-code lookup (no code persistence).
    return Response(501,
        body: jsonEncode({'error': 'Not implemented'}),
        headers: {'Content-Type': 'application/json'});
  });

  router.post('/<code>/accept', (Request request, String code) async {
    final userId = _extractUserId(request);
    if (userId == null) return Response(401, body: jsonEncode({'error': 'Unauthorized'}));
    // NOT IMPLEMENTED: share-by-code acceptance.
    return Response(501,
        body: jsonEncode({'error': 'Not implemented'}),
        headers: {'Content-Type': 'application/json'});
  });

  return router;
}
