import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dbcrypt/dbcrypt.dart';

import 'jwt_secret.dart';

final _uuid = Uuid();
final _dbcrypt = DBCrypt();
const _jsonHeaders = {'Content-Type': 'application/json'};

String _signAccessToken(String userId, String email) {
  final jwt = JWT({'id': userId, 'email': email});
  return jwt.sign(SecretKey(jwtSecret), expiresIn: Duration(minutes: 30));
}

String _signRefreshToken(String userId, String email) {
  final jwt = JWT({'id': userId, 'email': email});
  return jwt.sign(SecretKey(jwtSecret), expiresIn: Duration(days: 30));
}

Map<String, dynamic>? _verifyToken(String token) {
  try {
    final jwt = JWT.verify(token, SecretKey(jwtSecret));
    return jwt.payload as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

String? _extractToken(Request request) {
  final auth = request.headers['authorization'] ??
      request.headers['Authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) return null;
  return auth.substring(7);
}

Map<String, dynamic> _userRowToMap(ResultRow row) {
  final c = row.toColumnMap();
  return {
    'id': c['id']?.toString(),
    'email': c['email'],
    'first_name': c['first_name'] ?? '',
    'last_name': c['last_name'] ?? '',
    'category': c['category'] ?? 'pet_guardian',
    'bio': c['bio'] ?? '',
    'photo_url': c['photo_url'] ?? '',
    'locale': c['locale'] ?? 'en',
    'created_at': c['created_at']?.toString(),
    'updated_at': c['updated_at']?.toString(),
  };
}

Router authRoutes(Pool pool) {
  final auth = Router();

  auth.post('/signup', (Request request) async {
    try {
      final body = json.decode(await request.readAsString()) as Map<String, dynamic>;
      final email = (body['email'] as String?)?.trim();
      final password = body['password'] as String?;
      final firstName = (body['first_name'] as String?) ?? '';
      final lastName = (body['last_name'] as String?) ?? '';
      final category = (body['category'] as String?) ?? 'pet_guardian';
      final bio = (body['bio'] as String?) ?? '';
      final photoUrl = (body['photo_url'] as String?) ?? '';
      final locale = (body['locale'] as String?) ?? 'en';

      if (email == null || email.isEmpty || password == null || password.isEmpty) {
        return Response(400,
            headers: _jsonHeaders,
            body: json.encode({'error': 'Email and password are required.'}));
      }

      final id = _uuid.v4();
      final passwordHash = _dbcrypt.hashpw(password, _dbcrypt.gensalt());

      try {
        await pool.execute(
          Sql.named(
              'INSERT INTO users (id, email, password_hash, first_name, last_name, category, bio, photo_url, locale) VALUES (@id, @email, @hash, @fn, @ln, @cat, @bio, @photo, @locale)'),
          parameters: {
            'id': id,
            'email': email,
            'hash': passwordHash,
            'fn': firstName,
            'ln': lastName,
            'cat': category,
            'bio': bio,
            'photo': photoUrl,
            'locale': locale,
          },
        );
      } on ServerException catch (e) {
        if (e.message.contains('unique') || e.message.contains('23505') || e.message.contains('duplicate')) {
          return Response(400,
              headers: _jsonHeaders,
              body: json.encode({'error': 'Email already exists.'}));
        }
        rethrow;
      }

      final user = {
        'id': id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'category': category,
        'bio': bio,
        'photo_url': photoUrl,
        'locale': locale,
      };

      final accessToken = _signAccessToken(id, email);
      final refreshToken = _signRefreshToken(id, email);

      return Response(201,
          headers: _jsonHeaders,
          body: json.encode({
            'user': user,
            'access_token': accessToken,
            'refresh_token': refreshToken,
          }));
    } catch (e) {
      print('Signup error: $e');
      return Response.internalServerError(
          headers: _jsonHeaders,
          body: json.encode({'error': 'Signup failed', 'details': '$e'}));
    }
  });

  auth.post('/login', (Request request) async {
    try {
      final body = json.decode(await request.readAsString()) as Map<String, dynamic>;
      final email = (body['email'] as String?)?.trim();
      final password = body['password'] as String?;

      if (email == null || email.isEmpty || password == null || password.isEmpty) {
        return Response(400,
            headers: _jsonHeaders,
            body: json.encode({'error': 'Email and password are required.'}));
      }

      final result = await pool.execute(
        Sql.named('SELECT * FROM users WHERE email = @email'),
        parameters: {'email': email},
      );

      if (result.isEmpty) {
        return Response(401,
            headers: _jsonHeaders,
            body: json.encode({'error': 'Invalid email or password.'}));
      }

      final row = result.first;
      final columns = row.toColumnMap();
      final storedHash = columns['password_hash'] as String;

      if (!_dbcrypt.checkpw(password, storedHash)) {
        return Response(401,
            headers: _jsonHeaders,
            body: json.encode({'error': 'Invalid email or password.'}));
      }

      final user = _userRowToMap(row);
      final accessToken = _signAccessToken(user['id']!, user['email']!);
      final refreshToken = _signRefreshToken(user['id']!, user['email']!);

      return Response.ok(
          json.encode({
            'user': user,
            'access_token': accessToken,
            'refresh_token': refreshToken,
          }),
          headers: _jsonHeaders);
    } catch (e) {
      print('Login error: $e');
      return Response.internalServerError(
          headers: _jsonHeaders,
          body: json.encode({'error': 'Login failed', 'details': '$e'}));
    }
  });

  auth.post('/refresh', (Request request) async {
    try {
      final body = json.decode(await request.readAsString()) as Map<String, dynamic>;
      final refreshToken = body['refresh_token'] as String?;

      if (refreshToken == null || refreshToken.isEmpty) {
        return Response(400,
            headers: _jsonHeaders,
            body: json.encode({'error': 'refresh_token is required'}));
      }

      final payload = _verifyToken(refreshToken);
      if (payload == null) {
        return Response(401,
            headers: _jsonHeaders,
            body: json.encode({'error': 'Invalid or expired refresh token'}));
      }

      final accessToken =
          _signAccessToken(payload['id'] as String, payload['email'] as String);

      return Response.ok(json.encode({'access_token': accessToken}),
          headers: _jsonHeaders);
    } catch (e) {
      return Response(401,
          headers: _jsonHeaders,
          body: json.encode({'error': 'Invalid or expired refresh token'}));
    }
  });

  auth.post('/logout', (Request request) async {
    return Response.ok(json.encode({'message': 'Logged out'}),
        headers: _jsonHeaders);
  });

  auth.get('/me', (Request request) async {
    final token = _extractToken(request);
    if (token == null) {
      return Response(401,
          headers: _jsonHeaders,
          body: json.encode({'error': 'Missing or invalid Authorization header'}));
    }

    final payload = _verifyToken(token);
    if (payload == null) {
      return Response(401,
          headers: _jsonHeaders,
          body: json.encode({'error': 'Invalid or expired token'}));
    }

    try {
      final result = await pool.execute(
        Sql.named('SELECT * FROM users WHERE id = @id'),
        parameters: {'id': payload['id']},
      );

      if (result.isEmpty) {
        return Response.notFound(
            json.encode({'error': 'User not found'}),
            headers: _jsonHeaders);
      }

      final user = _userRowToMap(result.first);
      return Response.ok(json.encode(user), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          headers: _jsonHeaders,
          body: json.encode({'error': 'Failed to fetch user'}));
    }
  });

  auth.put('/me', (Request request) async {
    final token = _extractToken(request);
    if (token == null) {
      return Response(401,
          headers: _jsonHeaders,
          body: json.encode({'error': 'Missing or invalid Authorization header'}));
    }

    final payload = _verifyToken(token);
    if (payload == null) {
      return Response(401,
          headers: _jsonHeaders,
          body: json.encode({'error': 'Invalid or expired token'}));
    }

    try {
      final body = json.decode(await request.readAsString()) as Map<String, dynamic>;
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
            headers: _jsonHeaders,
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

      final user = _userRowToMap(result.first);
      return Response.ok(json.encode(user), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          headers: _jsonHeaders,
          body: json.encode({'error': 'Update failed', 'details': '$e'}));
    }
  });

  auth.post('/me/photo', (Request request) async {
    final token = _extractToken(request);
    if (token == null) {
      return Response(401,
          headers: _jsonHeaders,
          body: json.encode({'error': 'Missing or invalid Authorization header'}));
    }

    final payload = _verifyToken(token);
    if (payload == null) {
      return Response(401,
          headers: _jsonHeaders,
          body: json.encode({'error': 'Invalid or expired token'}));
    }

    try {
      final contentType = request.headers['content-type'] ?? '';
      if (!contentType.contains('multipart/form-data')) {
        return Response(400,
            headers: _jsonHeaders,
            body: json.encode({'error': 'Expected multipart/form-data'}));
      }

      final boundary = contentType.split('boundary=').last;
      final bytes = await request.read().expand((e) => e).toList();
      final bodyStr = String.fromCharCodes(bytes);

      final photoDir = Directory('uploads/photos');
      if (!photoDir.existsSync()) {
        photoDir.createSync(recursive: true);
      }

      final filename = '${payload['id']}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${photoDir.path}/$filename';

      final parts = bodyStr.split('--$boundary');
      for (final part in parts) {
        if (part.contains('name="photo"')) {
          final headerEnd = part.indexOf('\r\n\r\n');
          if (headerEnd == -1) continue;
          final fileBytes = bytes.sublist(
            bodyStr.indexOf('\r\n\r\n', bodyStr.indexOf('name="photo"')) + 4,
          );
          final endBoundary = fileBytes.length -
              '--$boundary--\r\n'.length;
          File(filePath).writeAsBytesSync(
            fileBytes.sublist(0, endBoundary > 0 ? endBoundary : fileBytes.length),
          );
          break;
        }
      }

      final photoUrl = '/uploads/photos/$filename';
      await pool.execute(
        Sql.named('UPDATE users SET photo_url = @photo, updated_at = NOW() WHERE id = @id'),
        parameters: {'photo': photoUrl, 'id': payload['id']},
      );

      final result = await pool.execute(
        Sql.named('SELECT * FROM users WHERE id = @id'),
        parameters: {'id': payload['id']},
      );

      final user = _userRowToMap(result.first);
      return Response.ok(json.encode(user), headers: _jsonHeaders);
    } catch (e) {
      print('Photo upload error: $e');
      return Response.internalServerError(
          headers: _jsonHeaders,
          body: json.encode({'error': 'Photo upload failed', 'details': '$e'}));
    }
  });

  auth.post('/change-password', (Request request) async {
    final token = _extractToken(request);
    if (token == null) {
      return Response(401,
          headers: _jsonHeaders,
          body: json.encode({'error': 'Missing or invalid Authorization header'}));
    }

    final payload = _verifyToken(token);
    if (payload == null) {
      return Response(401,
          headers: _jsonHeaders,
          body: json.encode({'error': 'Invalid or expired token'}));
    }

    try {
      final body = json.decode(await request.readAsString()) as Map<String, dynamic>;
      final currentPassword = body['currentPassword'] as String?;
      final newPassword = body['newPassword'] as String?;

      if (currentPassword == null || newPassword == null) {
        return Response(400,
            headers: _jsonHeaders,
            body: json.encode({'error': 'Current and new passwords are required'}));
      }

      final result = await pool.execute(
        Sql.named('SELECT password_hash FROM users WHERE id = @id'),
        parameters: {'id': payload['id']},
      );

      if (result.isEmpty) {
        return Response.notFound(
            json.encode({'error': 'User not found'}), headers: _jsonHeaders);
      }

      final storedHash = result.first.toColumnMap()['password_hash'] as String;
      if (!_dbcrypt.checkpw(currentPassword, storedHash)) {
        return Response(400,
            headers: _jsonHeaders,
            body: json.encode({'error': 'Current password is incorrect'}));
      }

      final newHash = _dbcrypt.hashpw(newPassword, _dbcrypt.gensalt());
      await pool.execute(
        Sql.named('UPDATE users SET password_hash = @hash, updated_at = NOW() WHERE id = @id'),
        parameters: {'hash': newHash, 'id': payload['id']},
      );

      return Response.ok(
          json.encode({'message': 'Password changed successfully'}),
          headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          headers: _jsonHeaders,
          body: json.encode({'error': 'Password change failed'}));
    }
  });

  auth.post('/forgot-password', (Request request) async {
    try {
      final body = json.decode(await request.readAsString()) as Map<String, dynamic>;
      final email = (body['email'] as String?)?.trim();

      if (email == null || email.isEmpty) {
        return Response(400,
            headers: _jsonHeaders,
            body: json.encode({'error': 'Email is required'}));
      }

      final result = await pool.execute(
        Sql.named('SELECT id FROM users WHERE email = @email'),
        parameters: {'email': email},
      );

      if (result.isEmpty) {
        return Response.ok(
            json.encode({'message': 'If that email exists, a reset code has been sent.'}),
            headers: _jsonHeaders);
      }

      final userId = result.first.toColumnMap()['id'].toString();
      final code = (100000 + Random().nextInt(900000)).toString();
      final id = _uuid.v4();

      await pool.execute(
        Sql.named(
            'INSERT INTO password_reset_tokens (id, user_id, code, expires_at) VALUES (@id, @uid, @code, NOW() + INTERVAL \'15 minutes\')'),
        parameters: {'id': id, 'uid': userId, 'code': code},
      );

      print('Password reset code for $email: $code');

      return Response.ok(
          json.encode({'message': 'If that email exists, a reset code has been sent.', 'code': code}),
          headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          headers: _jsonHeaders,
          body: json.encode({'error': 'Request failed'}));
    }
  });

  auth.post('/reset-password', (Request request) async {
    try {
      final body = json.decode(await request.readAsString()) as Map<String, dynamic>;
      final email = (body['email'] as String?)?.trim();
      final code = body['code'] as String?;
      final newPassword = body['new_password'] as String?;

      if (email == null || code == null || newPassword == null) {
        return Response(400,
            headers: _jsonHeaders,
            body: json.encode({'error': 'Email, code, and new_password are required'}));
      }

      final result = await pool.execute(
        Sql.named('''
          SELECT prt.id, prt.user_id FROM password_reset_tokens prt
          JOIN users u ON u.id = prt.user_id
          WHERE u.email = @email AND prt.code = @code AND prt.used = false AND prt.expires_at > NOW()
          ORDER BY prt.created_at DESC LIMIT 1
        '''),
        parameters: {'email': email, 'code': code},
      );

      if (result.isEmpty) {
        return Response(400,
            headers: _jsonHeaders,
            body: json.encode({'error': 'Invalid or expired reset code'}));
      }

      final tokenRow = result.first.toColumnMap();
      final tokenId = tokenRow['id'].toString();
      final userId = tokenRow['user_id'].toString();

      final newHash = _dbcrypt.hashpw(newPassword, _dbcrypt.gensalt());

      await pool.execute(
        Sql.named('UPDATE users SET password_hash = @hash, updated_at = NOW() WHERE id = @id'),
        parameters: {'hash': newHash, 'id': userId},
      );

      await pool.execute(
        Sql.named('UPDATE password_reset_tokens SET used = true WHERE id = @id'),
        parameters: {'id': tokenId},
      );

      return Response.ok(
          json.encode({'message': 'Password has been reset successfully'}),
          headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          headers: _jsonHeaders,
          body: json.encode({'error': 'Reset failed'}));
    }
  });

  auth.delete('/me', (Request request) async {
    final token = _extractToken(request);
    if (token == null) {
      return Response(401,
          headers: _jsonHeaders,
          body: json.encode({'error': 'Missing or invalid Authorization header'}));
    }

    final payload = _verifyToken(token);
    if (payload == null) {
      return Response(401,
          headers: _jsonHeaders,
          body: json.encode({'error': 'Invalid or expired token'}));
    }

    try {
      final body = json.decode(await request.readAsString()) as Map<String, dynamic>;
      final password = body['password'] as String?;

      if (password == null || password.isEmpty) {
        return Response(400,
            headers: _jsonHeaders,
            body: json.encode({'error': 'Password is required'}));
      }

      final result = await pool.execute(
        Sql.named('SELECT password_hash FROM users WHERE id = @id'),
        parameters: {'id': payload['id']},
      );

      if (result.isEmpty) {
        return Response.notFound(
            json.encode({'error': 'User not found'}), headers: _jsonHeaders);
      }

      final storedHash = result.first.toColumnMap()['password_hash'] as String;
      if (!_dbcrypt.checkpw(password, storedHash)) {
        return Response(400,
            headers: _jsonHeaders,
            body: json.encode({'error': 'Password is incorrect'}));
      }

      await pool.execute(
        Sql.named('DELETE FROM users WHERE id = @id'),
        parameters: {'id': payload['id']},
      );

      return Response.ok(
          json.encode({'message': 'Account deleted successfully'}),
          headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          headers: _jsonHeaders,
          body: json.encode({'error': 'Account deletion failed'}));
    }
  });

  auth.get('/me/export', (Request request) async {
    final token = _extractToken(request);
    if (token == null) {
      return Response(401,
          headers: _jsonHeaders,
          body: json.encode({'error': 'Missing or invalid Authorization header'}));
    }

    final payload = _verifyToken(token);
    if (payload == null) {
      return Response(401,
          headers: _jsonHeaders,
          body: json.encode({'error': 'Invalid or expired token'}));
    }

    try {
      final userId = payload['id'] as String;

      final userResult = await pool.execute(
        Sql.named('SELECT * FROM users WHERE id = @id'),
        parameters: {'id': userId},
      );

      if (userResult.isEmpty) {
        return Response.notFound(
            json.encode({'error': 'User not found'}), headers: _jsonHeaders);
      }

      final user = _userRowToMap(userResult.first);

      final petsResult = await pool.execute(
        Sql.named('SELECT * FROM pets WHERE user_id = @id'),
        parameters: {'id': userId},
      );
      final pets = petsResult.map((r) => r.toColumnMap()).toList();

      final vetsResult = await pool.execute(
        Sql.named('SELECT * FROM vets WHERE user_id = @id'),
        parameters: {'id': userId},
      );
      final vets = vetsResult.map((r) => r.toColumnMap()).toList();

      return Response.ok(
          json.encode({
            'user': user,
            'pets': pets,
            'vets': vets,
            'exported_at': DateTime.now().toIso8601String(),
          }),
          headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          headers: _jsonHeaders,
          body: json.encode({'error': 'Data export failed'}));
    }
  });

  return auth;
}
