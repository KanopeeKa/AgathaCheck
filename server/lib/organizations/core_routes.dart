import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import '../http_security.dart';
import 'org_shared.dart';

void registerOrgCoreRoutes(Router router, Pool pool) {
  final orgUuid = Uuid();
  router.get('/', (Request request) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
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
      final orgs = results.map((row) => orgRowToMap(row)).toList();
      return Response.ok(jsonEncode(orgs), headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode(
              {'error': publicError(e, 'Error fetching organizations')}),
          headers: orgJsonHeaders);
    }
  });

  router.get('/<id>', (Request request, String id) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
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
        return Response.notFound(
            jsonEncode({'error': 'Organization not found'}),
            headers: orgJsonHeaders);
      }
      return Response.ok(jsonEncode(orgRowToMap(results.first)),
          headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.post('/', (Request request) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      final data =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final orgId = orgUuid.v4();
      await pool.execute(
        Sql.named(
            'INSERT INTO organizations (id, name, type, email, phone, address, website, bio, photo_url) VALUES (@id, @name, @type, @email, @phone, @address, @website, @bio, @photo_url)'),
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
        Sql.named(
            'INSERT INTO organization_users (id, organization_id, user_id, role) VALUES (@id, @orgId, @userId, \'super_user\')'),
        parameters: {'id': orgUuid.v4(), 'orgId': orgId, 'userId': userId},
      );
      final results = await pool.execute(
        Sql.named('''
            SELECT o.*, 'super_user' as role,
              1 as member_count, 0 as pet_count
            FROM organizations o WHERE o.id = @id
          '''),
        parameters: {'id': orgId},
      );
      return Response(201,
          body: jsonEncode(orgRowToMap(results.first)),
          headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e, 'Error creating org')}),
          headers: orgJsonHeaders);
    }
  });

  router.put('/<id>', (Request request, String id) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!isOrgAdmin(await getOrgMemberRole(pool, id, userId)))
        return orgForbidden();
      final data =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      await pool.execute(
        Sql.named(
            'UPDATE organizations SET name = @name, type = @type, email = @email, phone = @phone, address = @address, website = @website, bio = @bio, photo_url = @photo_url, updated_at = NOW() WHERE id = @id'),
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
        return Response.notFound(
            jsonEncode({'error': 'Organization not found'}),
            headers: orgJsonHeaders);
      }
      return Response.ok(jsonEncode(orgRowToMap(results.first)),
          headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });

  router.delete('/<id>', (Request request, String id) async {
    final userId = extractOrgUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: orgJsonHeaders);
    }
    try {
      if (!isOrgAdmin(await getOrgMemberRole(pool, id, userId)))
        return orgForbidden();
      await pool.execute(
        Sql.named('DELETE FROM organizations WHERE id = @id'),
        parameters: {'id': id},
      );
      return Response.ok(jsonEncode({'deleted': true}),
          headers: orgJsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: orgJsonHeaders);
    }
  });
}
