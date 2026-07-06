import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../http_security.dart';
import 'org_shared.dart';

void registerOrgPetsRoutes(Router router, Pool pool) {
    router.get('/<id>/pets', (Request request, String id) async {
      final userId = extractOrgUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
      }
      try {
        if (!isActiveOrgMember(await getOrgMemberRole(pool, id, userId))) return orgForbidden();
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
        return Response.ok(jsonEncode(pets), headers: orgJsonHeaders);
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
      }
    });
  
    router.get('/<id>/archived', (Request request, String id) async {
      final userId = extractOrgUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
      }
      try {
        if (!isActiveOrgMember(await getOrgMemberRole(pool, id, userId))) return orgForbidden();
        final results = await pool.execute(
          Sql.named('SELECT * FROM archived_pets WHERE organization_id = @orgId ORDER BY created_at DESC'),
          parameters: {'orgId': id},
        );
        final archived = results.map((row) {
          final c = row.toColumnMap();
          return c.map((k, v) => MapEntry(k, v?.toString()));
        }).toList();
        return Response.ok(jsonEncode(archived), headers: orgJsonHeaders);
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
      }
    });
}
