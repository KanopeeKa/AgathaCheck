import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../http_security.dart';
import 'auth_shared.dart';
import '../gdpr_user_export.dart';

void registerProfileRoutes(Router router, Pool pool) {
  router.get('/me', (Request request) async {
    final token = extractToken(request);
    if (token == null) {
      return Response(401,
          headers: jsonHeaders,
          body: json
              .encode({'error': 'Missing or invalid Authorization header'}));
    }

    final payload = verifyToken(token);
    if (payload == null) {
      return Response(401,
          headers: jsonHeaders,
          body: json.encode({'error': 'Invalid or expired token'}));
    }

    try {
      final result = await pool.execute(
        Sql.named('SELECT * FROM users WHERE id = @id'),
        parameters: {'id': payload['id']},
      );

      if (result.isEmpty) {
        return Response.notFound(json.encode({'error': 'User not found'}),
            headers: jsonHeaders);
      }

      final user = userRowToMap(result.first);
      return Response.ok(json.encode(user), headers: jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          headers: jsonHeaders,
          body: json.encode({'error': 'Failed to fetch user'}));
    }
  });

  router.put('/me', (Request request) async {
    final token = extractToken(request);
    if (token == null) {
      return Response(401,
          headers: jsonHeaders,
          body: json
              .encode({'error': 'Missing or invalid Authorization header'}));
    }

    final payload = verifyToken(token);
    if (payload == null) {
      return Response(401,
          headers: jsonHeaders,
          body: json.encode({'error': 'Invalid or expired token'}));
    }

    try {
      final body =
          json.decode(await request.readAsString()) as Map<String, dynamic>;
      final updates = <String>[];
      final params = <String, dynamic>{'id': payload['id']};

      if (body.containsKey('first_name')) {
        updates.add('first_name = @fn');
        params['fn'] = body['first_name'];
      }
      if (body.containsKey('last_name')) {
        updates.add('last_name = @ln');
        params['ln'] = body['last_name'];
      }
      if (body.containsKey('category')) {
        updates.add('category = @cat');
        params['cat'] = body['category'];
      }
      if (body.containsKey('bio')) {
        updates.add('bio = @bio');
        params['bio'] = body['bio'];
      }
      if (body.containsKey('locale')) {
        updates.add('locale = @locale');
        params['locale'] = body['locale'];
      }
      if (body.containsKey('photo_url')) {
        updates.add('photo_url = @photo');
        params['photo'] = body['photo_url'];
      }

      if (updates.isEmpty) {
        return Response(400,
            headers: jsonHeaders,
            body: json.encode({'error': 'No fields to update'}));
      }

      updates.add('updated_at = NOW()');

      await pool.execute(
        Sql.named('UPDATE users SET ${updates.join(', ')} WHERE id = @id'),
        parameters: params,
      );

      final result = await pool.execute(
        Sql.named('SELECT * FROM users WHERE id = @id'),
        parameters: {'id': payload['id']},
      );

      final user = userRowToMap(result.first);
      return Response.ok(json.encode(user), headers: jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          headers: jsonHeaders,
          body: json.encode({'error': 'Update failed', ...errorDetails(e)}));
    }
  });

  router.post('/me/photo', (Request request) async {
    final token = extractToken(request);
    if (token == null) {
      return Response(401,
          headers: jsonHeaders,
          body: json
              .encode({'error': 'Missing or invalid Authorization header'}));
    }

    final payload = verifyToken(token);
    if (payload == null) {
      return Response(401,
          headers: jsonHeaders,
          body: json.encode({'error': 'Invalid or expired token'}));
    }

    try {
      final contentType = request.headers['content-type'] ?? '';
      if (!contentType.contains('multipart/form-data')) {
        return Response(400,
            headers: jsonHeaders,
            body: json.encode({'error': 'Expected multipart/form-data'}));
      }

      final boundary = contentType.split('boundary=').last;
      final bytes = await request.read().expand((e) => e).toList();
      final bodyStr = String.fromCharCodes(bytes);

      final photoDir = Directory('uploads/photos');
      if (!photoDir.existsSync()) {
        photoDir.createSync(recursive: true);
      }

      final filename =
          '${payload['id']}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${photoDir.path}/$filename';

      final parts = bodyStr.split('--$boundary');
      for (final part in parts) {
        if (part.contains('name="photo"')) {
          final headerEnd = part.indexOf('\r\n\r\n');
          if (headerEnd == -1) continue;
          final fileBytes = bytes.sublist(
            bodyStr.indexOf('\r\n\r\n', bodyStr.indexOf('name="photo"')) + 4,
          );
          final endBoundary = fileBytes.length - '--$boundary--\r\n'.length;
          File(filePath).writeAsBytesSync(
            fileBytes.sublist(
                0, endBoundary > 0 ? endBoundary : fileBytes.length),
          );
          break;
        }
      }

      final photoUrl = '/uploads/photos/$filename';
      await pool.execute(
        Sql.named(
            'UPDATE users SET photo_url = @photo, updated_at = NOW() WHERE id = @id'),
        parameters: {'photo': photoUrl, 'id': payload['id']},
      );

      final result = await pool.execute(
        Sql.named('SELECT * FROM users WHERE id = @id'),
        parameters: {'id': payload['id']},
      );

      final user = userRowToMap(result.first);
      return Response.ok(json.encode(user), headers: jsonHeaders);
    } catch (e) {
      print('Photo upload error: $e');
      return Response.internalServerError(
          headers: jsonHeaders,
          body: json
              .encode({'error': 'Photo upload failed', ...errorDetails(e)}));
    }
  });

  router.get('/me/export', (Request request) async {
    final token = extractToken(request);
    if (token == null) {
      return Response(401,
          headers: jsonHeaders,
          body: json
              .encode({'error': 'Missing or invalid Authorization header'}));
    }

    final payload = verifyToken(token);
    if (payload == null) {
      return Response(401,
          headers: jsonHeaders,
          body: json.encode({'error': 'Invalid or expired token'}));
    }

    try {
      final userId = payload['id'] as String;

      final userResult = await pool.execute(
        Sql.named('SELECT * FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );

      if (userResult.isEmpty) {
        return Response.notFound(json.encode({'error': 'User not found'}),
            headers: jsonHeaders);
      }

      final user = userRowToMap(userResult.first);

      final exportData = await buildUserDataExport(pool, userId);

      return Response.ok(
          json.encode({
            'user': user,
            ...exportData,
            'exported_at': DateTime.now().toIso8601String(),
          }),
          headers: jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          headers: jsonHeaders,
          body: json.encode({'error': 'Data export failed'}));
    }
  });

  router.delete('/me', (Request request) async {
    final token = extractToken(request);
    if (token == null) {
      return Response(401,
          headers: jsonHeaders,
          body: json
              .encode({'error': 'Missing or invalid Authorization header'}));
    }

    final payload = verifyToken(token);
    if (payload == null) {
      return Response(401,
          headers: jsonHeaders,
          body: json.encode({'error': 'Invalid or expired token'}));
    }

    try {
      final body =
          json.decode(await request.readAsString()) as Map<String, dynamic>;
      final password = body['password'] as String?;

      if (password == null || password.isEmpty) {
        return Response(400,
            headers: jsonHeaders,
            body: json.encode({'error': 'Password is required'}));
      }

      final result = await pool.execute(
        Sql.named('SELECT password_hash FROM users WHERE id = @id'),
        parameters: {'id': payload['id']},
      );

      if (result.isEmpty) {
        return Response.notFound(json.encode({'error': 'User not found'}),
            headers: jsonHeaders);
      }

      final storedHash = result.first.toColumnMap()['password_hash'] as String;
      if (!dbcrypt.checkpw(password, storedHash)) {
        return Response(400,
            headers: jsonHeaders,
            body: json.encode({'error': 'Password is incorrect'}));
      }

      await pool.execute(
        Sql.named('DELETE FROM users WHERE id = @id'),
        parameters: {'id': payload['id']},
      );

      return Response.ok(
          json.encode({'message': 'Account deleted successfully'}),
          headers: jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          headers: jsonHeaders,
          body: json.encode({'error': 'Account deletion failed'}));
    }
  });
}
