import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../http_security.dart';
import '../rate_limit.dart';
import '../validation.dart';
import 'auth_shared.dart';

void registerSessionRoutes(Router router, Pool pool) {
  router.post('/signup', (Request request) async {
    final limited = checkAuthRateLimit(request);
    if (limited != null) return limited;
    try {
      final body =
          json.decode(await request.readAsString()) as Map<String, dynamic>;
      final email = (body['email'] as String?)?.trim();
      final password = body['password'] as String?;
      final firstName = (body['first_name'] as String?) ?? '';
      final lastName = (body['last_name'] as String?) ?? '';
      final category = (body['category'] as String?) ?? 'pet_guardian';
      final bio = (body['bio'] as String?) ?? '';
      final photoUrl = (body['photo_url'] as String?) ?? '';
      final locale = (body['locale'] as String?) ?? 'en';

      if (email == null ||
          email.isEmpty ||
          password == null ||
          password.isEmpty) {
        return Response(400,
            headers: jsonHeaders,
            body: json.encode({'error': 'Email and password are required.'}));
      }
      if (!isValidEmail(email)) {
        return Response(400,
            headers: jsonHeaders,
            body: json.encode({'error': 'Invalid email format.'}));
      }
      if (!isStrongPassword(password)) {
        return Response(400,
            headers: jsonHeaders,
            body: json.encode({
              'error':
                  'Password must be at least $minPasswordLength characters.'
            }));
      }

      final id = uuid.v4();
      final passwordHash = dbcrypt.hashpw(password, dbcrypt.gensalt());

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
        if (e.message.contains('unique') ||
            e.message.contains('23505') ||
            e.message.contains('duplicate')) {
          return Response(400,
              headers: jsonHeaders,
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

      final accessToken = signAccessToken(id, email);
      final refreshToken = signRefreshToken(id, email);

      return Response(201,
          headers: jsonHeaders,
          body: json.encode({
            'user': user,
            'access_token': accessToken,
            'refresh_token': refreshToken,
          }));
    } catch (e) {
      print('Signup error: $e');
      return Response.internalServerError(
          headers: jsonHeaders,
          body: json.encode({'error': 'Signup failed', ...errorDetails(e)}));
    }
  });

  router.post('/login', (Request request) async {
    final limited = checkAuthRateLimit(request);
    if (limited != null) return limited;
    try {
      final body =
          json.decode(await request.readAsString()) as Map<String, dynamic>;
      final email = (body['email'] as String?)?.trim();
      final password = body['password'] as String?;

      if (email == null ||
          email.isEmpty ||
          password == null ||
          password.isEmpty) {
        return Response(400,
            headers: jsonHeaders,
            body: json.encode({'error': 'Email and password are required.'}));
      }

      final result = await pool.execute(
        Sql.named('SELECT * FROM users WHERE email = @email'),
        parameters: {'email': email},
      );

      if (result.isEmpty) {
        return Response(401,
            headers: jsonHeaders,
            body: json.encode({'error': 'Invalid email or password.'}));
      }

      final row = result.first;
      final columns = row.toColumnMap();
      final storedHash = columns['password_hash'] as String;

      if (!dbcrypt.checkpw(password, storedHash)) {
        return Response(401,
            headers: jsonHeaders,
            body: json.encode({'error': 'Invalid email or password.'}));
      }

      final user = userRowToMap(row);
      final accessToken = signAccessToken(user['id']!, user['email']!);
      final refreshToken = signRefreshToken(user['id']!, user['email']!);

      return Response.ok(
          json.encode({
            'user': user,
            'access_token': accessToken,
            'refresh_token': refreshToken,
          }),
          headers: jsonHeaders);
    } catch (e) {
      print('Login error: $e');
      return Response.internalServerError(
          headers: jsonHeaders,
          body: json.encode({'error': 'Login failed', ...errorDetails(e)}));
    }
  });

  router.post('/refresh', (Request request) async {
    try {
      final body =
          json.decode(await request.readAsString()) as Map<String, dynamic>;
      final refreshToken = body['refresh_token'] as String?;

      if (refreshToken == null || refreshToken.isEmpty) {
        return Response(400,
            headers: jsonHeaders,
            body: json.encode({'error': 'refresh_token is required'}));
      }

      final payload = verifyToken(refreshToken);
      if (payload == null) {
        return Response(401,
            headers: jsonHeaders,
            body: json.encode({'error': 'Invalid or expired refresh token'}));
      }

      // Bind the refresh to a live account: a token for a since-deleted user
      // must not keep minting access tokens until it expires.
      final userResult = await pool.execute(
        Sql.named('SELECT id FROM users WHERE id = @id'),
        parameters: {'id': payload['id']},
      );
      if (userResult.isEmpty) {
        return Response(401,
            headers: jsonHeaders,
            body: json.encode({'error': 'Invalid or expired refresh token'}));
      }

      final accessToken =
          signAccessToken(payload['id'] as String, payload['email'] as String);

      return Response.ok(json.encode({'access_token': accessToken}),
          headers: jsonHeaders);
    } catch (e) {
      return Response(401,
          headers: jsonHeaders,
          body: json.encode({'error': 'Invalid or expired refresh token'}));
    }
  });

  router.post('/logout', (Request request) async {
    return Response.ok(json.encode({'message': 'Logged out'}),
        headers: jsonHeaders);
  });
}
