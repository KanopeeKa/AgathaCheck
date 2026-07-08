import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../calendar_date.dart';
import '../../foster_placements.dart';
import '../../http_security.dart';
import '../../notification_helper.dart';
import '../org_shared.dart';

void registerOrgPlacementsActionRoutes(Router router, Pool pool) {
  router.post('/<orgId>/placements/<placementId>/end', (
    Request request,
    String orgId,
    String placementId,
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
      final endDate =
          normalizeCalendarDateInput(data['end_date'] ?? data['endDate']);

      final placementResult = await pool.execute(
        Sql.named(
            'SELECT * FROM foster_placements WHERE id = @placementId AND organization_id = @orgId'),
        parameters: {'placementId': placementId, 'orgId': orgId},
      );
      if (placementResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Placement not found'}),
            headers: orgJsonHeaders);
      }
      final placement = placementResult.first.toColumnMap();
      if (![placementStatusPending, placementStatusInProgress]
          .contains(placement['status'])) {
        return Response(400,
            body: jsonEncode({'error': 'Placement is not active'}),
            headers: orgJsonHeaders);
      }

      final petResult = await pool.execute(
        Sql.named('SELECT name FROM pets WHERE id = @petId'),
        parameters: {'petId': placement['pet_id']},
      );
      final petName =
          petResult.isEmpty ? 'Pet' : petResult.first.toColumnMap()['name'];

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
        jsonEncode(placementToMap(updateResult.first.toColumnMap(),
            extras: {'pet_name': petName})),
        headers: orgJsonHeaders,
      );
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.post('/<orgId>/placements/<placementId>/start-adoption', (
    Request request,
    String orgId,
    String placementId,
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
      final adoptionConditions =
          (data['adoption_conditions'] ?? data['adoptionConditions'] ?? '')
              .toString()
              .trim();

      final placementResult = await pool.execute(
        Sql.named(
            'SELECT * FROM foster_placements WHERE id = @placementId AND organization_id = @orgId'),
        parameters: {'placementId': placementId, 'orgId': orgId},
      );
      if (placementResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Placement not found'}),
            headers: orgJsonHeaders);
      }
      final placement = placementResult.first.toColumnMap();
      if (placement['status'] != placementStatusInProgress) {
        return Response(400,
            body: jsonEncode(
                {'error': 'Placement must be in progress to start adoption'}),
            headers: orgJsonHeaders);
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
      final petName =
          petResult.isEmpty ? 'Pet' : petResult.first.toColumnMap()['name'];

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
      return Response.ok(jsonEncode(placementToMap(detail ?? placement)),
          headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.post('/<orgId>/placements/<placementId>/complete-conditions', (
    Request request,
    String orgId,
    String placementId,
  ) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!await requireOrgAdmin(pool, orgId, userId)) return orgForbidden();

      final placementResult = await pool.execute(
        Sql.named(
            'SELECT * FROM foster_placements WHERE id = @placementId AND organization_id = @orgId'),
        parameters: {'placementId': placementId, 'orgId': orgId},
      );
      if (placementResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Placement not found'}),
            headers: orgJsonHeaders);
      }
      final placement = placementResult.first.toColumnMap();
      if (placement['status'] != placementStatusPendingConditions) {
        return Response(400,
            body: jsonEncode(
                {'error': 'Placement is not awaiting condition completion'}),
            headers: orgJsonHeaders);
      }

      await pool.execute(
        Sql.named('''
          UPDATE foster_placements SET status = @status, updated_at = NOW() WHERE id = @placementId
        '''),
        parameters: {
          'status': placementStatusWaitingAdoption,
          'placementId': placementId
        },
      );

      final petResult = await pool.execute(
        Sql.named('SELECT name FROM pets WHERE id = @petId'),
        parameters: {'petId': placement['pet_id']},
      );
      final petName =
          petResult.isEmpty ? 'Pet' : petResult.first.toColumnMap()['name'];

      await createNotification(
        pool,
        userId: placement['foster_user_id'].toString(),
        petId: placement['pet_id']?.toString(),
        petName: petName?.toString(),
        title: 'Adoption ready to confirm',
        message:
            'Pre-adoption conditions for $petName are complete. Please confirm adoption.',
      );

      final detail = await loadPlacementDetail(pool, placementId);
      return Response.ok(jsonEncode(placementToMap(detail ?? placement)),
          headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.post('/<orgId>/placements/<placementId>/cancel-adoption', (
    Request request,
    String orgId,
    String placementId,
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
      final endDate =
          normalizeCalendarDateInput(data['end_date'] ?? data['endDate']);

      final placementResult = await pool.execute(
        Sql.named(
            'SELECT * FROM foster_placements WHERE id = @placementId AND organization_id = @orgId'),
        parameters: {'placementId': placementId, 'orgId': orgId},
      );
      if (placementResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Placement not found'}),
            headers: orgJsonHeaders);
      }
      final placement = placementResult.first.toColumnMap();
      if (![placementStatusWaitingAdoption, placementStatusPendingConditions]
          .contains(placement['status'])) {
        return Response(400,
            body: jsonEncode({'error': 'Placement is not in an adoption step'}),
            headers: orgJsonHeaders);
      }

      final petResult = await pool.execute(
        Sql.named('SELECT name FROM pets WHERE id = @petId'),
        parameters: {'petId': placement['pet_id']},
      );
      final petName =
          petResult.isEmpty ? 'Pet' : petResult.first.toColumnMap()['name'];

      final updated =
          await cancelAdoptionPlacement(pool, placement, endDate: endDate);

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
        jsonEncode(
            placementToMap(detail ?? updated, extras: {'pet_name': petName})),
        headers: orgJsonHeaders,
      );
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });
}
