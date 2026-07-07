import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../http_security.dart';
import 'org_shared.dart';

void registerOrgInvitesRoutes(Router router, Pool pool) {
  router.get('/invites/pending', (Request request) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
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
      return Response.ok(jsonEncode(invites), headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.post('/invites/<id>/accept', (Request request, String id) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named(
            'UPDATE organization_users SET role = REPLACE(role, \'pending_\', \'\'), updated_at = NOW() WHERE id = @id AND user_id = @userId RETURNING *'),
        parameters: {'id': id, 'userId': userId},
      );
      if (results.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Invite not found'}),
            headers: orgJsonHeaders);
      }
      final c = results.first.toColumnMap();
      return Response.ok(
          jsonEncode({
            'id': c['id']?.toString(),
            'organization_id': c['organization_id']?.toString(),
            'role': c['role'],
          }),
          headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.post('/invites/<id>/decline', (Request request, String id) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      await pool.execute(
        Sql.named(
            'DELETE FROM organization_users WHERE id = @id AND user_id = @userId AND role LIKE \'pending_%\''),
        parameters: {'id': id, 'userId': userId},
      );
      return Response.ok(jsonEncode({'success': true}),
          headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });
}
