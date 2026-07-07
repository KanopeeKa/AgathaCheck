import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../calendar_date.dart';
import '../foster_placements.dart';
import '../http_security.dart';
import '../notification_helper.dart';
import '../org_roles.dart';
import 'org_shared.dart';

void registerOrgPlacementsRoutes(Router router, Pool pool) {
  final orgUuid = Uuid();

  Future<List<Map<String, dynamic>>> _loadPlacementRows(
    String sql,
    Map<String, dynamic> parameters,
  ) async {
    final results = await pool.execute(Sql.named(sql), parameters: parameters);
    return results.map((r) => placementToMap(r.toColumnMap())).toList();
  }

  const placementDetailSelect = '''
    SELECT fp.*,
           p.name AS pet_name,
           p.species AS pet_species,
           o.name AS organization_name,
           TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS foster_name,
           u.email AS foster_email
  ''';

  router.get('/<orgId>/placements', (Request request, String orgId) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      final placements = await _loadPlacementRows('''
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
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.get('/<orgId>/pets/<petId>/foster-history', (
    Request request,
    String orgId,
    String petId,
  ) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      final petResult = await pool.execute(
        Sql.named('SELECT id FROM pets WHERE id = @petId AND organization_id = @orgId'),
        parameters: {'petId': petId, 'orgId': orgId},
      );
      if (petResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Pet not found'}), headers: orgJsonHeaders);
      }
      final placements = await _loadPlacementRows('''
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
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.get('/<orgId>/pets/<petId>/placement', (
    Request request,
    String orgId,
    String petId,
  ) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      final petResult = await pool.execute(
        Sql.named('SELECT id FROM pets WHERE id = @petId AND organization_id = @orgId'),
        parameters: {'petId': petId, 'orgId': orgId},
      );
      if (petResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Pet not found'}), headers: orgJsonHeaders);
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
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.post('/<orgId>/pets/<petId>/placements', (
    Request request,
    String orgId,
    String petId,
  ) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final fosterUserId =
          (data['foster_user_id'] ?? data['fosterUserId'])?.toString();
      final startDate = normalizeCalendarDateInput(data['start_date'] ?? data['startDate']);
      final notes = (data['notes'] ?? '').toString().trim();

      if (fosterUserId == null || fosterUserId.isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Foster parent user is required'}), headers: orgJsonHeaders);
      }

      final petResult = await pool.execute(
        Sql.named('SELECT id, name FROM pets WHERE id = @petId AND organization_id = @orgId'),
        parameters: {'petId': petId, 'orgId': orgId},
      );
      if (petResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Pet not found'}), headers: orgJsonHeaders);
      }
      final pet = petResult.first.toColumnMap();

      final fosterMember = await pool.execute(
        Sql.named('SELECT role FROM organization_users WHERE organization_id = @orgId AND user_id = @fosterUserId'),
        parameters: {'orgId': orgId, 'fosterUserId': fosterUserId},
      );
      if (fosterMember.isEmpty ||
          !isFosterParentMemberRole(fosterMember.first.toColumnMap()['role']?.toString())) {
        return Response(400, body: jsonEncode({'error': 'Selected user is not a foster parent for this organization'}), headers: orgJsonHeaders);
      }

      final existing = await getActivePlacementForPet(pool, petId);
      if (existing != null) {
        return Response(409, body: jsonEncode({'error': 'Pet already has an active foster placement'}), headers: orgJsonHeaders);
      }

      final placementId = orgUuid.v4();
      await pool.execute(
        Sql.named('''
          INSERT INTO foster_placements (
            id, organization_id, pet_id, foster_user_id, status, start_date, notes, created_by
          ) VALUES (@id, @orgId, @petId, @fosterUserId, @status, @startDate::date, @notes, @createdBy)
        '''),
        parameters: {
          'id': placementId,
          'orgId': orgId,
          'petId': petId,
          'fosterUserId': fosterUserId,
          'status': placementStatusPending,
          'startDate': startDate,
          'notes': notes,
          'createdBy': userId,
        },
      );

      final adminResult = await pool.execute(
        Sql.named('SELECT first_name, last_name, email FROM users WHERE id = @userId'),
        parameters: {'userId': userId},
      );
      final adminName = adminResult.isEmpty
          ? 'Someone'
          : userDisplayName(adminResult.first.toColumnMap());

      await createNotification(
        pool,
        userId: fosterUserId,
        petId: petId,
        petName: pet['name']?.toString(),
        title: 'Foster placement request',
        message: '$adminName invited you to foster ${pet['name']}.',
      );

      final detail = await loadPlacementDetail(pool, placementId);
      return Response(
        201,
        body: jsonEncode(placementToMap(detail ?? {'id': placementId})),
        headers: orgJsonHeaders,
      );
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.post('/<orgId>/placements/<placementId>/end', (
    Request request,
    String orgId,
    String placementId,
  ) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final endDate = normalizeCalendarDateInput(data['end_date'] ?? data['endDate']);

      final placementResult = await pool.execute(
        Sql.named('SELECT * FROM foster_placements WHERE id = @placementId AND organization_id = @orgId'),
        parameters: {'placementId': placementId, 'orgId': orgId},
      );
      if (placementResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Placement not found'}), headers: orgJsonHeaders);
      }
      final placement = placementResult.first.toColumnMap();
      if (![placementStatusPending, placementStatusInProgress].contains(placement['status'])) {
        return Response(400, body: jsonEncode({'error': 'Placement is not active'}), headers: orgJsonHeaders);
      }

      final petResult = await pool.execute(
        Sql.named('SELECT name FROM pets WHERE id = @petId'),
        parameters: {'petId': placement['pet_id']},
      );
      final petName = petResult.isEmpty ? 'Pet' : petResult.first.toColumnMap()['name'];

      final updateResult = await pool.execute(
        Sql.named('''
          UPDATE foster_placements
          SET status = @status,
              end_date = COALESCE(@endDate::date, CURRENT_DATE),
              updated_at = NOW()
          WHERE id = @placementId
          RETURNING *
        '''),
        parameters: {
          'status': placementStatusNotInFoster,
          'endDate': endDate,
          'placementId': placementId,
        },
      );

      if (placement['status'] == placementStatusInProgress) {
        await revokeFosterPetAccess(
          pool,
          placement['pet_id'].toString(),
          placement['foster_user_id'].toString(),
        );
      }

      await createNotification(
        pool,
        userId: placement['foster_user_id'].toString(),
        petId: placement['pet_id']?.toString(),
        petName: petName?.toString(),
        title: 'Foster period ended',
        message: 'The foster period for $petName has ended.',
      );

      return Response.ok(
        jsonEncode(placementToMap(updateResult.first.toColumnMap(), extras: {'pet_name': petName})),
        headers: orgJsonHeaders,
      );
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.post('/<orgId>/placements/<placementId>/start-adoption', (
    Request request,
    String orgId,
    String placementId,
  ) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final adoptionConditions =
          (data['adoption_conditions'] ?? data['adoptionConditions'] ?? '').toString().trim();

      final placementResult = await pool.execute(
        Sql.named('SELECT * FROM foster_placements WHERE id = @placementId AND organization_id = @orgId'),
        parameters: {'placementId': placementId, 'orgId': orgId},
      );
      if (placementResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Placement not found'}), headers: orgJsonHeaders);
      }
      final placement = placementResult.first.toColumnMap();
      if (placement['status'] != placementStatusInProgress) {
        return Response(400, body: jsonEncode({'error': 'Placement must be in progress to start adoption'}), headers: orgJsonHeaders);
      }

      final nextStatus = adoptionConditions.isNotEmpty
          ? placementStatusPendingConditions
          : placementStatusWaitingAdoption;

      await pool.execute(
        Sql.named('''
          UPDATE foster_placements
          SET status = @status, adoption_conditions = @conditions, updated_at = NOW()
          WHERE id = @placementId
        '''),
        parameters: {
          'status': nextStatus,
          'conditions': adoptionConditions,
          'placementId': placementId,
        },
      );

      final petResult = await pool.execute(
        Sql.named('SELECT name FROM pets WHERE id = @petId'),
        parameters: {'petId': placement['pet_id']},
      );
      final petName = petResult.isEmpty ? 'Pet' : petResult.first.toColumnMap()['name'];

      await createNotification(
        pool,
        userId: placement['foster_user_id'].toString(),
        petId: placement['pet_id']?.toString(),
        petName: petName?.toString(),
        title: 'Adoption ready to confirm',
        message: adoptionConditions.isNotEmpty
            ? '$petName is ready for adoption once pre-adoption conditions are met.'
            : 'Please confirm adoption of $petName.',
      );

      final detail = await loadPlacementDetail(pool, placementId);
      return Response.ok(jsonEncode(placementToMap(detail ?? placement)), headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.post('/<orgId>/placements/<placementId>/complete-conditions', (
    Request request,
    String orgId,
    String placementId,
  ) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();

      final placementResult = await pool.execute(
        Sql.named('SELECT * FROM foster_placements WHERE id = @placementId AND organization_id = @orgId'),
        parameters: {'placementId': placementId, 'orgId': orgId},
      );
      if (placementResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Placement not found'}), headers: orgJsonHeaders);
      }
      final placement = placementResult.first.toColumnMap();
      if (placement['status'] != placementStatusPendingConditions) {
        return Response(400, body: jsonEncode({'error': 'Placement is not awaiting condition completion'}), headers: orgJsonHeaders);
      }

      await pool.execute(
        Sql.named('''
          UPDATE foster_placements SET status = @status, updated_at = NOW() WHERE id = @placementId
        '''),
        parameters: {'status': placementStatusWaitingAdoption, 'placementId': placementId},
      );

      final petResult = await pool.execute(
        Sql.named('SELECT name FROM pets WHERE id = @petId'),
        parameters: {'petId': placement['pet_id']},
      );
      final petName = petResult.isEmpty ? 'Pet' : petResult.first.toColumnMap()['name'];

      await createNotification(
        pool,
        userId: placement['foster_user_id'].toString(),
        petId: placement['pet_id']?.toString(),
        petName: petName?.toString(),
        title: 'Adoption ready to confirm',
        message: 'Pre-adoption conditions for $petName are complete. Please confirm adoption.',
      );

      final detail = await loadPlacementDetail(pool, placementId);
      return Response.ok(jsonEncode(placementToMap(detail ?? placement)), headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.post('/<orgId>/placements/<placementId>/cancel-adoption', (
    Request request,
    String orgId,
    String placementId,
  ) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final endDate = normalizeCalendarDateInput(data['end_date'] ?? data['endDate']);

      final placementResult = await pool.execute(
        Sql.named('SELECT * FROM foster_placements WHERE id = @placementId AND organization_id = @orgId'),
        parameters: {'placementId': placementId, 'orgId': orgId},
      );
      if (placementResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Placement not found'}), headers: orgJsonHeaders);
      }
      final placement = placementResult.first.toColumnMap();
      if (![placementStatusWaitingAdoption, placementStatusPendingConditions]
          .contains(placement['status'])) {
        return Response(400, body: jsonEncode({'error': 'Placement is not in an adoption step'}), headers: orgJsonHeaders);
      }

      final petResult = await pool.execute(
        Sql.named('SELECT name FROM pets WHERE id = @petId'),
        parameters: {'petId': placement['pet_id']},
      );
      final petName = petResult.isEmpty ? 'Pet' : petResult.first.toColumnMap()['name'];

      final updated = await cancelAdoptionPlacement(pool, placement, endDate: endDate);

      await createNotification(
        pool,
        userId: placement['foster_user_id'].toString(),
        petId: placement['pet_id']?.toString(),
        petName: petName?.toString(),
        title: 'Adoption cancelled',
        message:
            'The adoption process for $petName was cancelled. The pet returns to organisation custody.',
      );

      final detail = await loadPlacementDetail(pool, placementId);
      return Response.ok(
        jsonEncode(placementToMap(detail ?? updated, extras: {'pet_name': petName})),
        headers: orgJsonHeaders,
      );
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.post('/<orgId>/pets/<petId>/placements/direct-adopt', (
    Request request,
    String orgId,
    String petId,
  ) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();
      final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final fosterUserId =
          (data['foster_user_id'] ?? data['fosterUserId'])?.toString();
      final adoptionConditions =
          (data['adoption_conditions'] ?? data['adoptionConditions'] ?? '').toString().trim();
      final notes = (data['notes'] ?? '').toString().trim();

      if (fosterUserId == null || fosterUserId.isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Foster parent user is required'}), headers: orgJsonHeaders);
      }

      final petResult = await pool.execute(
        Sql.named('SELECT id, name FROM pets WHERE id = @petId AND organization_id = @orgId'),
        parameters: {'petId': petId, 'orgId': orgId},
      );
      if (petResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Pet not found'}), headers: orgJsonHeaders);
      }
      final pet = petResult.first.toColumnMap();

      final fosterMember = await pool.execute(
        Sql.named('SELECT role FROM organization_users WHERE organization_id = @orgId AND user_id = @fosterUserId'),
        parameters: {'orgId': orgId, 'fosterUserId': fosterUserId},
      );
      if (fosterMember.isEmpty ||
          !isFosterParentMemberRole(fosterMember.first.toColumnMap()['role']?.toString())) {
        return Response(400, body: jsonEncode({'error': 'Selected user is not a foster parent for this organization'}), headers: orgJsonHeaders);
      }

      final existing = await getActivePlacementForPet(pool, petId);
      if (existing != null) {
        return Response(409, body: jsonEncode({'error': 'Pet already has an active foster placement'}), headers: orgJsonHeaders);
      }

      final placementId = orgUuid.v4();
      final nextStatus = adoptionConditions.isNotEmpty
          ? placementStatusPendingConditions
          : placementStatusWaitingAdoption;

      await pool.execute(
        Sql.named('''
          INSERT INTO foster_placements (
            id, organization_id, pet_id, foster_user_id, status, notes,
            adoption_conditions, created_by
          ) VALUES (@id, @orgId, @petId, @fosterUserId, @status, @notes, @conditions, @createdBy)
        '''),
        parameters: {
          'id': placementId,
          'orgId': orgId,
          'petId': petId,
          'fosterUserId': fosterUserId,
          'status': nextStatus,
          'notes': notes,
          'conditions': adoptionConditions,
          'createdBy': userId,
        },
      );

      final adminResult = await pool.execute(
        Sql.named('SELECT first_name, last_name, email FROM users WHERE id = @userId'),
        parameters: {'userId': userId},
      );
      final adminName = adminResult.isEmpty
          ? 'Someone'
          : userDisplayName(adminResult.first.toColumnMap());

      await createNotification(
        pool,
        userId: fosterUserId,
        petId: petId,
        petName: pet['name']?.toString(),
        title: 'Adoption ready to confirm',
        message: adoptionConditions.isNotEmpty
            ? '$adminName invited you to adopt ${pet['name']}. Pre-adoption conditions apply.'
            : '$adminName invited you to adopt ${pet['name']}. Please confirm to complete adoption.',
      );

      final detail = await loadPlacementDetail(pool, placementId);
      return Response(
        201,
        body: jsonEncode(placementToMap(detail ?? {'id': placementId})),
        headers: orgJsonHeaders,
      );
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });
}
