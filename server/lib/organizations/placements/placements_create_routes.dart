import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../../calendar_date.dart';
import '../../foster_placements.dart';
import '../../http_security.dart';
import '../../notification_helper.dart';
import '../../org_roles.dart';
import '../org_shared.dart';

void registerOrgPlacementsCreateRoutes(Router router, Pool pool) {
  final orgUuid = Uuid();
  router.post('/<orgId>/pets/<petId>/placements', (
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
      final data =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final fosterUserId =
          (data['foster_user_id'] ?? data['fosterUserId'])?.toString();
      final startDate =
          normalizeCalendarDateInput(data['start_date'] ?? data['startDate']);
      final notes = (data['notes'] ?? '').toString().trim();

      if (fosterUserId == null || fosterUserId.isEmpty) {
        return Response(400,
            body: jsonEncode({'error': 'Foster parent user is required'}),
            headers: orgJsonHeaders);
      }

      final petResult = await pool.execute(
        Sql.named(
            'SELECT id, name FROM pets WHERE id = @petId AND organization_id = @orgId'),
        parameters: {'petId': petId, 'orgId': orgId},
      );
      if (petResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Pet not found'}),
            headers: orgJsonHeaders);
      }
      final pet = petResult.first.toColumnMap();

      final fosterMember = await pool.execute(
        Sql.named(
            'SELECT role FROM organization_users WHERE organization_id = @orgId AND user_id = @fosterUserId'),
        parameters: {'orgId': orgId, 'fosterUserId': fosterUserId},
      );
      if (fosterMember.isEmpty ||
          !isFosterParentMemberRole(
              fosterMember.first.toColumnMap()['role']?.toString())) {
        return Response(400,
            body: jsonEncode({
              'error':
                  'Selected user is not a foster parent for this organization'
            }),
            headers: orgJsonHeaders);
      }

      final existing = await getActivePlacementForPet(pool, petId);
      if (existing != null) {
        return Response(409,
            body: jsonEncode(
                {'error': 'Pet already has an active foster placement'}),
            headers: orgJsonHeaders);
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
        Sql.named(
            'SELECT first_name, last_name, email FROM users WHERE id = @userId'),
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
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });
  router.post('/<orgId>/pets/<petId>/placements/direct-adopt', (
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
      final data =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final fosterUserId =
          (data['foster_user_id'] ?? data['fosterUserId'])?.toString();
      final adoptionConditions =
          (data['adoption_conditions'] ?? data['adoptionConditions'] ?? '')
              .toString()
              .trim();
      final notes = (data['notes'] ?? '').toString().trim();

      if (fosterUserId == null || fosterUserId.isEmpty) {
        return Response(400,
            body: jsonEncode({'error': 'Foster parent user is required'}),
            headers: orgJsonHeaders);
      }

      final petResult = await pool.execute(
        Sql.named(
            'SELECT id, name FROM pets WHERE id = @petId AND organization_id = @orgId'),
        parameters: {'petId': petId, 'orgId': orgId},
      );
      if (petResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Pet not found'}),
            headers: orgJsonHeaders);
      }
      final pet = petResult.first.toColumnMap();

      final fosterMember = await pool.execute(
        Sql.named(
            'SELECT role FROM organization_users WHERE organization_id = @orgId AND user_id = @fosterUserId'),
        parameters: {'orgId': orgId, 'fosterUserId': fosterUserId},
      );
      if (fosterMember.isEmpty ||
          !isFosterParentMemberRole(
              fosterMember.first.toColumnMap()['role']?.toString())) {
        return Response(400,
            body: jsonEncode({
              'error':
                  'Selected user is not a foster parent for this organization'
            }),
            headers: orgJsonHeaders);
      }

      final existing = await getActivePlacementForPet(pool, petId);
      if (existing != null) {
        return Response(409,
            body: jsonEncode(
                {'error': 'Pet already has an active foster placement'}),
            headers: orgJsonHeaders);
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
        Sql.named(
            'SELECT first_name, last_name, email FROM users WHERE id = @userId'),
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
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });
}
