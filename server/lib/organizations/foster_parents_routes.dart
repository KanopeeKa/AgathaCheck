import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../foster_placements.dart';
import '../http_security.dart';
import '../org_roles.dart';
import 'org_shared.dart';

void registerOrgFosterParentsRoutes(Router router, Pool pool) {
  final orgUuid = Uuid();

  Map<String, dynamic> fosterParentToMap(Map<String, dynamic> row) {
    var activePets = row['active_pets'];
    if (activePets is String) {
      try {
        activePets = jsonDecode(activePets);
      } catch (_) {
        activePets = [];
      }
    }
    final displayName = (row['display_name']?.toString() ?? '').trim();
    return {
      'id': row['id']?.toString(),
      'kind': row['kind'],
      'user_id': row['user_id']?.toString(),
      'display_name': displayName.isNotEmpty ? displayName : row['email'],
      'email': row['email'],
      'phone': row['phone'],
      'foster_address': row['foster_address']?.toString() ?? '',
      'notes': row['notes']?.toString() ?? '',
      'role': row['role'] != null
          ? normaliseOrgRole(row['role']?.toString())
          : null,
      'photo_url': row['photo_url'],
      'active_pet_count':
          int.tryParse(row['active_pet_count']?.toString() ?? '') ?? 0,
      'active_pets': activePets ?? [],
    };
  }

  router.get('/<orgId>/foster-parents', (Request request, String orgId) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();

      final memberResult = await pool.execute(
        Sql('''
          SELECT ou.id,
                 'member' AS kind,
                 u.id AS user_id,
                 TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS display_name,
                 u.email,
                 u.photo_url,
                 ou.role,
                 NULL::varchar AS phone,
                 ''::text AS notes,
                 ''::text AS foster_address,
                 (
                   SELECT COUNT(DISTINCT fpl.pet_id)::int
                   FROM foster_placements fpl
                   WHERE fpl.organization_id = ou.organization_id
                     AND fpl.foster_user_id = u.id
                     AND fpl.status IN (${openPlacementStatusesSql()})
                 ) AS active_pet_count,
                 (
                   SELECT COALESCE(json_agg(json_build_object(
                     'pet_id', p.id,
                     'pet_name', p.name,
                     'status', fpl.status
                   ) ORDER BY p.name), '[]'::json)
                   FROM foster_placements fpl
                   JOIN pets p ON p.id = fpl.pet_id
                   WHERE fpl.organization_id = ou.organization_id
                     AND fpl.foster_user_id = u.id
                     AND fpl.status IN (${openPlacementStatusesSql()})
                 ) AS active_pets
          FROM organization_users ou
          JOIN users u ON u.id = ou.user_id
          WHERE ou.organization_id = @orgId
            AND ou.role IN (${fosterParentMemberRolesSql()})
          ORDER BY display_name, u.email
        '''),
        parameters: {'orgId': orgId},
      );

      final externalResult = await pool.execute(
        Sql('''
          SELECT fp.id,
                 'external' AS kind,
                 fp.user_id,
                 fp.display_name,
                 fp.email,
                 NULL AS photo_url,
                 NULL AS role,
                 fp.phone,
                 fp.notes,
                 fp.foster_address,
                 (
                   SELECT COUNT(DISTINCT fpl.pet_id)::int
                   FROM foster_placements fpl
                   WHERE fpl.organization_id = fp.organization_id
                     AND fpl.org_foster_parent_id = fp.id
                     AND fpl.status IN (${openPlacementStatusesSql()})
                 ) AS active_pet_count,
                 (
                   SELECT COALESCE(json_agg(json_build_object(
                     'pet_id', p.id,
                     'pet_name', p.name,
                     'status', fpl.status
                   ) ORDER BY p.name), '[]'::json)
                   FROM foster_placements fpl
                   JOIN pets p ON p.id = fpl.pet_id
                   WHERE fpl.organization_id = fp.organization_id
                     AND fpl.org_foster_parent_id = fp.id
                     AND fpl.status IN (${openPlacementStatusesSql()})
                 ) AS active_pets
          FROM org_foster_parents fp
          WHERE fp.organization_id = @orgId
          ORDER BY fp.display_name
        '''),
        parameters: {'orgId': orgId},
      );

      final combined = [
        ...memberResult.map((r) => fosterParentToMap(r.toColumnMap())),
        ...externalResult.map((r) => fosterParentToMap(r.toColumnMap())),
      ]..sort((a, b) => (a['display_name'] as String? ?? '')
          .toLowerCase()
          .compareTo((b['display_name'] as String? ?? '').toLowerCase()));

      return Response.ok(jsonEncode(combined), headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.post('/<orgId>/foster-parents', (Request request, String orgId) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      final data =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final displayName =
          (data['display_name'] ?? data['displayName'] ?? '').toString().trim();
      final email = (data['email'] ?? '').toString().trim();
      final phone = (data['phone'] ?? '').toString().trim();
      final fosterAddress =
          (data['foster_address'] ?? data['fosterAddress'] ?? '')
              .toString()
              .trim();
      final notes = (data['notes'] ?? '').toString().trim();
      final lawfulBasisConfirmed = data['lawful_basis_confirmed'] == true ||
          data['lawfulBasisConfirmed'] == true;

      if (displayName.isEmpty) {
        return Response(400,
            body: jsonEncode({'error': 'Display name is required'}),
            headers: orgJsonHeaders);
      }
      if (!lawfulBasisConfirmed) {
        return Response(400,
            body:
                jsonEncode({'error': 'Lawful basis confirmation is required'}),
            headers: orgJsonHeaders);
      }
      if (email.isEmpty) {
        return Response(400,
            body: jsonEncode(
                {'error': 'Email is required for external foster contacts'}),
            headers: orgJsonHeaders);
      }

      final id = orgUuid.v4();
      final result = await pool.execute(
        Sql.named('''
          INSERT INTO org_foster_parents (
            id, organization_id, display_name, email, phone, foster_address, notes,
            lawful_basis_attested_at, lawful_basis_attested_by
          ) VALUES (@id, @orgId, @displayName, @email, @phone, @fosterAddress, @notes, NOW(), @userId)
          RETURNING *
        '''),
        parameters: {
          'id': id,
          'orgId': orgId,
          'displayName': displayName,
          'email': email,
          'phone': phone.isEmpty ? null : phone,
          'fosterAddress': fosterAddress,
          'notes': notes,
          'userId': userId,
        },
      );
      final row = result.first.toColumnMap();
      return Response(
        201,
        body: jsonEncode(fosterParentToMap({
          ...row,
          'kind': 'external',
          'photo_url': null,
          'role': null,
          'active_pet_count': 0,
          'active_pets': [],
        })),
        headers: orgJsonHeaders,
      );
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.put('/<orgId>/foster-parents/<fosterParentId>', (
    Request request,
    String orgId,
    String fosterParentId,
  ) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      final data =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final displayName =
          (data['display_name'] ?? data['displayName'] ?? '').toString().trim();
      final email = (data['email'] ?? '').toString().trim();
      final phone = (data['phone'] ?? '').toString().trim();
      final fosterAddress =
          (data['foster_address'] ?? data['fosterAddress'] ?? '')
              .toString()
              .trim();
      final notes = (data['notes'] ?? '').toString().trim();

      if (displayName.isEmpty) {
        return Response(400,
            body: jsonEncode({'error': 'Display name is required'}),
            headers: orgJsonHeaders);
      }

      final result = await pool.execute(
        Sql.named('''
          UPDATE org_foster_parents
          SET display_name = @displayName, email = @email, phone = @phone,
              foster_address = @fosterAddress, notes = @notes, updated_at = NOW()
          WHERE id = @fosterParentId AND organization_id = @orgId
          RETURNING *
        '''),
        parameters: {
          'displayName': displayName,
          'email': email.isEmpty ? null : email,
          'phone': phone.isEmpty ? null : phone,
          'fosterAddress': fosterAddress,
          'notes': notes,
          'fosterParentId': fosterParentId,
          'orgId': orgId,
        },
      );
      if (result.isEmpty) {
        return Response.notFound(
            jsonEncode({'error': 'Foster parent not found'}),
            headers: orgJsonHeaders);
      }
      final row = result.first.toColumnMap();
      return Response.ok(
        jsonEncode(fosterParentToMap({
          ...row,
          'kind': 'external',
          'photo_url': null,
          'role': null,
          'active_pet_count': 0,
          'active_pets': [],
        })),
        headers: orgJsonHeaders,
      );
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.delete('/<orgId>/foster-parents/<fosterParentId>', (
    Request request,
    String orgId,
    String fosterParentId,
  ) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      final result = await pool.execute(
        Sql.named('''
          DELETE FROM org_foster_parents
          WHERE id = @fosterParentId AND organization_id = @orgId
          RETURNING id
        '''),
        parameters: {'fosterParentId': fosterParentId, 'orgId': orgId},
      );
      if (result.isEmpty) {
        return Response.notFound(
            jsonEncode({'error': 'Foster parent not found'}),
            headers: orgJsonHeaders);
      }
      return Response.ok(
        jsonEncode({'deleted': true, 'id': fosterParentId}),
        headers: orgJsonHeaders,
      );
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });
}
