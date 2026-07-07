import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import '../http_security.dart';
import '../org_people.dart';
import '../org_roles.dart';
import 'org_shared.dart';

void registerOrgMembersRoutes(Router router, Pool pool) {
  final orgUuid = Uuid();
  router.get('/<id>/members', (Request request, String id) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, id, userId)) return orgForbidden();
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
          'role': normaliseOrgRole(c['role']?.toString()),
          'created_at': c['created_at']?.toString(),
        };
      }).toList();
      return Response.ok(jsonEncode(members), headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.post('/<id>/invite', (Request request, String id) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      final actorRole = await getOrgMemberRole(pool, id, userId);
      if (!isOrgAdmin(actorRole)) return orgForbidden();
      final data =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final email = data['email'] as String?;
      final role = data['role'] as String? ?? orgRoleAdmin;
      if (email == null || email.isEmpty) {
        return Response(400,
            body: jsonEncode({'error': 'Email is required'}),
            headers: orgJsonHeaders);
      }
      if (!assignableOrgRoles.contains(role)) {
        return Response(400,
            body: jsonEncode({'error': 'Invalid role'}),
            headers: orgJsonHeaders);
      }
      if (!canAssignOrgRole(actorRole, role)) {
        return Response(403,
            body: jsonEncode({'error': 'Forbidden'}), headers: orgJsonHeaders);
      }
      final userResult = await pool.execute(
        Sql.named('SELECT id FROM users WHERE email = @email'),
        parameters: {'email': email},
      );
      if (userResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'User not found'}),
            headers: orgJsonHeaders);
      }
      final inviteeId = userResult.first.toColumnMap()['id']?.toString();
      final pendingRole = 'pending_$role';
      await pool.execute(
        Sql.named(
            'INSERT INTO organization_users (id, organization_id, user_id, role) VALUES (@id, @orgId, @userId, @role) ON CONFLICT (organization_id, user_id) DO UPDATE SET role = @role'),
        parameters: {
          'id': orgUuid.v4(),
          'orgId': id,
          'userId': inviteeId,
          'role': pendingRole
        },
      );
      return Response.ok(jsonEncode({'success': true, 'user_id': inviteeId}),
          headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.get('/<orgId>/people', (Request request, String orgId) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      final people = await listOrgPeople(pool, orgId);
      return Response.ok(jsonEncode(people), headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.get('/<orgId>/people/<kind>/<personId>', (
    Request request,
    String orgId,
    String kind,
    String personId,
  ) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    if (kind != 'member' && kind != 'external') {
      return Response(400,
          body: jsonEncode({'error': 'Invalid person kind'}),
          headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      final detail = await getOrgPersonDetail(pool, orgId, kind, personId);
      if (detail == null) {
        return Response.notFound(jsonEncode({'error': 'Person not found'}),
            headers: orgJsonHeaders);
      }
      return Response.ok(jsonEncode(detail), headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.put('/<orgId>/people/<kind>/<personId>/contact', (
    Request request,
    String orgId,
    String kind,
    String personId,
  ) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    if (kind != 'member' && kind != 'external') {
      return Response(400,
          body: jsonEncode({'error': 'Invalid person kind'}),
          headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      final data =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      await updateOrgPersonContact(pool, orgId, kind, personId, data);
      final detail = await getOrgPersonDetail(pool, orgId, kind, personId);
      if (detail == null) {
        return Response.notFound(jsonEncode({'error': 'Person not found'}),
            headers: orgJsonHeaders);
      }
      return Response.ok(jsonEncode(detail), headers: orgJsonHeaders);
    } on OrgPeopleValidationException catch (e) {
      return Response(400,
          body: jsonEncode({'error': e.message}), headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.put('/<orgId>/members/<memberUserId>/role', (
    Request request,
    String orgId,
    String memberUserId,
  ) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      final actorRole = await getOrgMemberRole(pool, orgId, userId);
      if (!isOrgAdmin(actorRole)) return orgForbidden();
      final data =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final role = data['role'] as String?;
      if (role == null || !assignableOrgRoles.contains(role)) {
        return Response(400,
            body: jsonEncode({'error': 'Invalid role'}),
            headers: orgJsonHeaders);
      }
      if (!canAssignOrgRole(actorRole, role)) {
        return Response(403,
            body: jsonEncode({'error': 'Forbidden'}), headers: orgJsonHeaders);
      }
      final results = await pool.execute(
        Sql.named('''
            UPDATE organization_users SET role = @role
            WHERE organization_id = @orgId AND user_id = @memberUserId
            RETURNING *
          '''),
        parameters: {
          'role': role,
          'orgId': orgId,
          'memberUserId': memberUserId
        },
      );
      if (results.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Member not found'}),
            headers: orgJsonHeaders);
      }
      final row = results.first.toColumnMap();
      return Response.ok(
        jsonEncode({...row, 'role': normaliseOrgRole(row['role']?.toString())}),
        headers: orgJsonHeaders,
      );
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.delete('/<orgId>/members/me', (Request request, String orgId) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      await pool.execute(
        Sql.named(
            'DELETE FROM organization_users WHERE organization_id = @orgId AND user_id = @userId'),
        parameters: {'orgId': orgId, 'userId': userId},
      );
      return Response.ok(jsonEncode({'message': 'Left organization'}),
          headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.delete('/<orgId>/members/<memberUserId>', (
    Request request,
    String orgId,
    String memberUserId,
  ) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      await pool.execute(
        Sql.named(
            'DELETE FROM organization_users WHERE organization_id = @orgId AND user_id = @memberUserId'),
        parameters: {'orgId': orgId, 'memberUserId': memberUserId},
      );
      return Response.ok(jsonEncode({'message': 'Member removed'}),
          headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });
}
