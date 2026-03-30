import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'dart:io';

final _uuid = Uuid();
final _jwtSecret = Platform.environment['JWT_SECRET'] ??
    Platform.environment['SESSION_SECRET'] ??
    'default_secret';
const _jsonHeaders = {'Content-Type': 'application/json'};

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

Router organizationRoutes(Pool pool) {
  final router = Router();

  router.get('/', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named('''
          SELECT o.*, ou.role,
            (SELECT COUNT(*) FROM organization_users WHERE organization_id = o.id) as member_count,
            0 as pet_count
          FROM organizations o
          JOIN organization_users ou ON ou.organization_id = o.id AND ou.user_id = @userId
          ORDER BY o.name
        '''),
        parameters: {'userId': userId},
      );
      final orgs = results.map((row) => _orgToMap(row)).toList();
      return Response.ok(jsonEncode(orgs), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error fetching organizations: $e'}), headers: _jsonHeaders);
    }
  });

  router.get('/invites/pending', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named('''
          SELECT ou.id, ou.organization_id, ou.role, o.name as org_name, o.type as org_type
          FROM organization_users ou
          JOIN organizations o ON o.id = ou.organization_id
          WHERE ou.user_id = @userId AND ou.role IN ('pending_member', 'pending_super_user')
          ORDER BY ou.created_at DESC
        '''),
        parameters: {'userId': userId},
      );
      final invites = results.map((row) {
        final c = row.toColumnMap();
        return {
          'id': c['id']?.toString(),
          'organization_id': c['organization_id']?.toString(),
          'role': c['role'],
          'org_name': c['org_name'],
          'org_type': c['org_type'],
        };
      }).toList();
      return Response.ok(jsonEncode(invites), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  router.post('/invites/<id>/accept', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named('UPDATE organization_users SET role = REPLACE(role, \'pending_\', \'\'), updated_at = NOW() WHERE id = @id AND user_id = @userId RETURNING *'),
        parameters: {'id': id, 'userId': userId},
      );
      if (results.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Invite not found'}), headers: _jsonHeaders);
      }
      final c = results.first.toColumnMap();
      return Response.ok(jsonEncode({
        'id': c['id']?.toString(),
        'organization_id': c['organization_id']?.toString(),
        'role': c['role'],
      }), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  router.post('/invites/<id>/decline', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      await pool.execute(
        Sql.named('DELETE FROM organization_users WHERE id = @id AND user_id = @userId AND role LIKE \'pending_%\''),
        parameters: {'id': id, 'userId': userId},
      );
      return Response.ok(jsonEncode({'success': true}), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  router.get('/<id>', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named('''
          SELECT o.*, ou.role,
            (SELECT COUNT(*) FROM organization_users WHERE organization_id = o.id) as member_count,
            0 as pet_count
          FROM organizations o
          JOIN organization_users ou ON ou.organization_id = o.id AND ou.user_id = @userId
          WHERE o.id = @id
        '''),
        parameters: {'id': id, 'userId': userId},
      );
      if (results.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Organization not found'}), headers: _jsonHeaders);
      }
      return Response.ok(jsonEncode(_orgToMap(results.first)), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  router.post('/', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final orgId = _uuid.v4();
      await pool.execute(
        Sql.named('INSERT INTO organizations (id, name, type, email, phone, address, website, bio, photo_url) VALUES (@id, @name, @type, @email, @phone, @address, @website, @bio, @photo_url)'),
        parameters: {
          'id': orgId,
          'name': data['name'] ?? '',
          'type': data['type'] ?? 'professional',
          'email': data['email'],
          'phone': data['phone'],
          'address': data['address'],
          'website': data['website'],
          'bio': data['bio'] ?? '',
          'photo_url': data['photo_url'] ?? '',
        },
      );
      await pool.execute(
        Sql.named('INSERT INTO organization_users (id, organization_id, user_id, role) VALUES (@id, @orgId, @userId, \'super_user\')'),
        parameters: {'id': _uuid.v4(), 'orgId': orgId, 'userId': userId},
      );
      final results = await pool.execute(
        Sql.named('''
          SELECT o.*, 'super_user' as role,
            1 as member_count, 0 as pet_count
          FROM organizations o WHERE o.id = @id
        '''),
        parameters: {'id': orgId},
      );
      return Response(201, body: jsonEncode(_orgToMap(results.first)), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error creating org: $e'}), headers: _jsonHeaders);
    }
  });

  router.put('/<id>', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      await pool.execute(
        Sql.named('UPDATE organizations SET name = @name, type = @type, email = @email, phone = @phone, address = @address, website = @website, bio = @bio, photo_url = @photo_url, updated_at = NOW() WHERE id = @id'),
        parameters: {
          'id': id,
          'name': data['name'] ?? '',
          'type': data['type'] ?? 'professional',
          'email': data['email'],
          'phone': data['phone'],
          'address': data['address'],
          'website': data['website'],
          'bio': data['bio'] ?? '',
          'photo_url': data['photo_url'] ?? '',
        },
      );
      final results = await pool.execute(
        Sql.named('''
          SELECT o.*, ou.role,
            (SELECT COUNT(*) FROM organization_users WHERE organization_id = o.id) as member_count,
            0 as pet_count
          FROM organizations o
          JOIN organization_users ou ON ou.organization_id = o.id AND ou.user_id = @userId
          WHERE o.id = @id
        '''),
        parameters: {'id': id, 'userId': userId},
      );
      if (results.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Organization not found'}), headers: _jsonHeaders);
      }
      return Response.ok(jsonEncode(_orgToMap(results.first)), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  router.delete('/<id>', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      await pool.execute(
        Sql.named('DELETE FROM organizations WHERE id = @id'),
        parameters: {'id': id},
      );
      return Response.ok(jsonEncode({'deleted': true}), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  router.get('/<id>/members', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named('''
          SELECT ou.id, ou.role, ou.created_at, u.id as user_id, u.email, u.first_name, u.last_name, u.photo_url
          FROM organization_users ou
          JOIN users u ON u.id = ou.user_id
          WHERE ou.organization_id = @orgId
          ORDER BY ou.created_at
        '''),
        parameters: {'orgId': id},
      );
      final members = results.map((row) {
        final c = row.toColumnMap();
        return {
          'id': c['id']?.toString(),
          'user_id': c['user_id']?.toString(),
          'email': c['email'],
          'first_name': c['first_name'],
          'last_name': c['last_name'],
          'photo_url': c['photo_url'],
          'role': c['role'],
          'created_at': c['created_at']?.toString(),
        };
      }).toList();
      return Response.ok(jsonEncode(members), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  router.post('/<id>/invite', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final email = data['email'] as String?;
      final role = data['role'] ?? 'member';
      if (email == null || email.isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Email is required'}), headers: _jsonHeaders);
      }
      final userResult = await pool.execute(
        Sql.named('SELECT id FROM users WHERE email = @email'),
        parameters: {'email': email},
      );
      if (userResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'User not found'}), headers: _jsonHeaders);
      }
      final inviteeId = userResult.first.toColumnMap()['id']?.toString();
      final pendingRole = 'pending_$role';
      await pool.execute(
        Sql.named('INSERT INTO organization_users (id, organization_id, user_id, role) VALUES (@id, @orgId, @userId, @role) ON CONFLICT (organization_id, user_id) DO UPDATE SET role = @role'),
        parameters: {'id': _uuid.v4(), 'orgId': id, 'userId': inviteeId, 'role': pendingRole},
      );
      return Response.ok(jsonEncode({'success': true, 'user_id': inviteeId}), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  router.get('/<id>/pets', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named('SELECT * FROM pets WHERE organization_id = @orgId ORDER BY created_at'),
        parameters: {'orgId': id},
      );
      final pets = results.map((row) {
        final c = row.toColumnMap();
        return {
          'id': c['id']?.toString(),
          'name': c['name'],
          'species': c['species'],
          'breed': c['breed'],
          'organization_id': c['organization_id']?.toString(),
        };
      }).toList();
      return Response.ok(jsonEncode(pets), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  router.get('/<id>/archived', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named('SELECT * FROM archived_pets WHERE organization_id = @orgId ORDER BY created_at DESC'),
        parameters: {'orgId': id},
      );
      final archived = results.map((row) {
        final c = row.toColumnMap();
        return c.map((k, v) => MapEntry(k, v?.toString()));
      }).toList();
      return Response.ok(jsonEncode(archived), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  return router;
}

Map<String, dynamic> _orgToMap(ResultRow row) {
  final c = row.toColumnMap();
  return {
    'id': c['id']?.toString(),
    'name': c['name'],
    'type': c['type'] ?? 'professional',
    'email': c['email'],
    'phone': c['phone'],
    'address': c['address'],
    'website': c['website'],
    'bio': c['bio'] ?? '',
    'photo_url': c['photo_url'] ?? '',
    'role': c['role'],
    'member_count': c['member_count'] ?? 0,
    'pet_count': c['pet_count'] ?? 0,
    'created_at': c['created_at']?.toString(),
    'updated_at': c['updated_at']?.toString(),
  };
}
