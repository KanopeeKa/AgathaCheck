import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import '../http_security.dart';
import 'org_shared.dart';

void registerOrgMembersRoutes(Router router, Pool pool) {
  final orgUuid = Uuid();
    router.get('/<id>/members', (Request request, String id) async {
      final userId = extractOrgUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
      }
      try {
        if (!isActiveOrgMember(await getOrgMemberRole(pool, id, userId))) return orgForbidden();
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
        return Response.ok(jsonEncode(members), headers: orgJsonHeaders);
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
      }
    });
  
    router.post('/<id>/invite', (Request request, String id) async {
      final userId = extractOrgUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
      }
      try {
        if (!isOrgAdmin(await getOrgMemberRole(pool, id, userId))) return orgForbidden();
        final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final email = data['email'] as String?;
        final role = data['role'] ?? 'member';
        if (email == null || email.isEmpty) {
          return Response(400, body: jsonEncode({'error': 'Email is required'}), headers: orgJsonHeaders);
        }
        if (!assignableOrgRoles.contains(role)) {
          return Response(400, body: jsonEncode({'error': 'Invalid role'}), headers: orgJsonHeaders);
        }
        final userResult = await pool.execute(
          Sql.named('SELECT id FROM users WHERE email = @email'),
          parameters: {'email': email},
        );
        if (userResult.isEmpty) {
          return Response.notFound(jsonEncode({'error': 'User not found'}), headers: orgJsonHeaders);
        }
        final inviteeId = userResult.first.toColumnMap()['id']?.toString();
        final pendingRole = 'pending_$role';
        await pool.execute(
          Sql.named('INSERT INTO organization_users (id, organization_id, user_id, role) VALUES (@id, @orgId, @userId, @role) ON CONFLICT (organization_id, user_id) DO UPDATE SET role = @role'),
          parameters: {'id': orgUuid.v4(), 'orgId': id, 'userId': inviteeId, 'role': pendingRole},
        );
        return Response.ok(jsonEncode({'success': true, 'user_id': inviteeId}), headers: orgJsonHeaders);
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
      }
    });
}
