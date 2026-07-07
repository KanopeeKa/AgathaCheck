import 'dart:convert';
import 'dart:math';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../http_security.dart';
import '../rate_limit.dart';
import '../validation.dart';
import 'auth_shared.dart';

void registerPasswordRoutes(Router router, Pool pool) {
  router.post('/change-password', (Request request) async {
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
      final currentPassword = body['currentPassword'] as String?;
      final newPassword = body['newPassword'] as String?;

      if (currentPassword == null || newPassword == null) {
        return Response(400,
            headers: jsonHeaders,
            body: json
                .encode({'error': 'Current and new passwords are required'}));
      }
      if (!isStrongPassword(newPassword)) {
        return Response(400,
            headers: jsonHeaders,
            body: json.encode({
              'error':
                  'Password must be at least $minPasswordLength characters.'
            }));
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
      if (!dbcrypt.checkpw(currentPassword, storedHash)) {
        return Response(400,
            headers: jsonHeaders,
            body: json.encode({'error': 'Current password is incorrect'}));
      }

      final newHash = dbcrypt.hashpw(newPassword, dbcrypt.gensalt());
      await pool.execute(
        Sql.named(
            'UPDATE users SET password_hash = @hash, updated_at = NOW() WHERE id = @id'),
        parameters: {'hash': newHash, 'id': payload['id']},
      );

      return Response.ok(
          json.encode({'message': 'Password changed successfully'}),
          headers: jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          headers: jsonHeaders,
          body: json.encode({'error': 'Password change failed'}));
    }
  });

  router.post('/forgot-password', (Request request) async {
    final limited = checkAuthRateLimit(request);
    if (limited != null) return limited;
    try {
      final body =
          json.decode(await request.readAsString()) as Map<String, dynamic>;
      final email = (body['email'] as String?)?.trim();

      if (email == null || email.isEmpty) {
        return Response(400,
            headers: jsonHeaders,
            body: json.encode({'error': 'Email is required'}));
      }

      final result = await pool.execute(
        Sql.named('SELECT id FROM users WHERE email = @email'),
        parameters: {'email': email},
      );

      if (result.isEmpty) {
        return Response.ok(
            json.encode({
              'message': 'If that email exists, a reset code has been sent.'
            }),
            headers: jsonHeaders);
      }

      final userId = result.first.toColumnMap()['id'].toString();
      // Cryptographically-secure 6-digit code (Random.secure(), not Random()).
      final code = (100000 + Random.secure().nextInt(900000)).toString();
      final id = uuid.v4();

      await pool.execute(
        Sql.named(
            'INSERT INTO password_reset_tokens (id, user_id, code, expires_at) VALUES (@id, @uid, @code, NOW() + INTERVAL \'15 minutes\')'),
        parameters: {'id': id, 'uid': userId, 'code': code},
      );

      // SECURITY: never return or log the reset code in production (it would be
      // an account-takeover oracle). In production it must be emailed/texted out
      // of band (not yet wired up). Outside production we expose it for local
      // dev/testing convenience only.
      final responseBody = <String, Object?>{
        'message': 'If that email exists, a reset code has been sent.'
      };
      if (!isProduction()) {
        print('Password reset code for $email: $code');
        responseBody['code'] = code;
      }

      return Response.ok(json.encode(responseBody), headers: jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          headers: jsonHeaders, body: json.encode({'error': 'Request failed'}));
    }
  });

  router.post('/reset-password', (Request request) async {
    final limited = checkAuthRateLimit(request);
    if (limited != null) return limited;
    try {
      final body =
          json.decode(await request.readAsString()) as Map<String, dynamic>;
      final email = (body['email'] as String?)?.trim();
      final code = body['code'] as String?;
      final newPassword = body['new_password'] as String?;

      if (email == null || code == null || newPassword == null) {
        return Response(400,
            headers: jsonHeaders,
            body: json.encode(
                {'error': 'Email, code, and new_password are required'}));
      }
      if (!isStrongPassword(newPassword)) {
        return Response(400,
            headers: jsonHeaders,
            body: json.encode({
              'error':
                  'Password must be at least $minPasswordLength characters.'
            }));
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
            headers: jsonHeaders,
            body: json.encode({'error': 'Invalid or expired reset code'}));
      }

      final tokenRow = result.first.toColumnMap();
      final tokenId = tokenRow['id'].toString();
      final userId = tokenRow['user_id'].toString();

      final newHash = dbcrypt.hashpw(newPassword, dbcrypt.gensalt());

      await pool.execute(
        Sql.named(
            'UPDATE users SET password_hash = @hash, updated_at = NOW() WHERE id = @id'),
        parameters: {'hash': newHash, 'id': userId},
      );

      await pool.execute(
        Sql.named(
            'UPDATE password_reset_tokens SET used = true WHERE id = @id'),
        parameters: {'id': tokenId},
      );

      return Response.ok(
          json.encode({'message': 'Password has been reset successfully'}),
          headers: jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          headers: jsonHeaders, body: json.encode({'error': 'Reset failed'}));
    }
  });
}
