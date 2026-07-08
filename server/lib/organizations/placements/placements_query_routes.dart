import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../foster_placements.dart';
import '../../http_security.dart';
import '../org_shared.dart';
import 'placements_shared.dart';

void registerOrgPlacementsQueryRoutes(Router router, Pool pool) {
  router.get('/<orgId>/placements', (Request request, String orgId) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      final placements = await loadPlacementRows(pool, '''
        $placementDetailSelect
        FROM foster_placements fp
        JOIN pets p ON p.id = fp.pet_id
        JOIN organizations o ON o.id = fp.organization_id
        JOIN users u ON u.id = fp.foster_user_id
        WHERE fp.organization_id = @orgId
        ORDER BY fp.created_at DESC
      ''', {'orgId': orgId});
      return Response.ok(jsonEncode(placements), headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.get('/<orgId>/pets/<petId>/foster-history', (
    Request request,
    String orgId,
    String petId,
  ) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      final petResult = await pool.execute(
        Sql.named(
            'SELECT id FROM pets WHERE id = @petId AND organization_id = @orgId'),
        parameters: {'petId': petId, 'orgId': orgId},
      );
      if (petResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Pet not found'}),
            headers: orgJsonHeaders);
      }
      final placements = await loadPlacementRows(pool, '''
        $placementDetailSelect
        FROM foster_placements fp
        JOIN pets p ON p.id = fp.pet_id
        JOIN organizations o ON o.id = fp.organization_id
        JOIN users u ON u.id = fp.foster_user_id
        WHERE fp.organization_id = @orgId AND fp.pet_id = @petId
        ORDER BY fp.created_at DESC
      ''', {'orgId': orgId, 'petId': petId});
      return Response.ok(jsonEncode(placements), headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.get('/<orgId>/pets/<petId>/placement', (
    Request request,
    String orgId,
    String petId,
  ) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      final petResult = await pool.execute(
        Sql.named(
            'SELECT id FROM pets WHERE id = @petId AND organization_id = @orgId'),
        parameters: {'petId': petId, 'orgId': orgId},
      );
      if (petResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Pet not found'}),
            headers: orgJsonHeaders);
      }
      final active = await getActivePlacementForPet(pool, petId);
      if (active == null) {
        return Response.ok(
          jsonEncode({'status': placementStatusNotInFoster, 'placement': null}),
          headers: orgJsonHeaders,
        );
      }
      final detail = await loadPlacementDetail(pool, active['id'].toString());
      return Response.ok(
        jsonEncode({
          'status': active['status'],
          'placement': detail == null ? null : placementToMap(detail),
        }),
        headers: orgJsonHeaders,
      );
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });
}
