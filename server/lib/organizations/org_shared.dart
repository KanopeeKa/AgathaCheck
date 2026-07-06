import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../jwt_secret.dart';

const orgJsonHeaders = {'Content-Type': 'application/json'};
const assignableOrgRoles = ['member', 'super_user'];

String? extractOrgUserId(Request request) {
  final auth =
      request.headers['authorization'] ?? request.headers['Authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) return null;
  try {
    final jwt = JWT.verify(auth.substring(7), SecretKey(jwtSecret));
    return (jwt.payload as Map)['id']?.toString();
  } catch (_) {
    return null;
  }
}

Future<String?> getOrgMemberRole(Pool pool, String orgId, String userId) async {
  final results = await pool.execute(
    Sql.named(
        'SELECT role FROM organization_users WHERE organization_id = @orgId AND user_id = @userId'),
    parameters: {'orgId': orgId, 'userId': userId},
  );
  if (results.isEmpty) return null;
  return results.first.toColumnMap()['role']?.toString();
}

bool isActiveOrgMember(String? role) =>
    role != null && !role.startsWith('pending_');
bool isOrgAdmin(String? role) => role == 'super_user';

Response orgForbidden() => Response(
      403,
      body: jsonEncode({'error': 'Forbidden'}),
      headers: orgJsonHeaders,
    );

Map<String, dynamic> orgRowToMap(ResultRow row) {
  final c = row.toColumnMap();
  return {
    'id': c['id']?.toString(),
    'name': c['name'],
    'type': c['type'] ?? 'professional',
    'email': c['email'],
    'phone': c['phone'],
    'address': c['address'],
    'website': c['website'],
    'bio': c['bio'] ?? '',
    'photo_url': c['photo_url'] ?? '',
    'role': c['role'],
    'member_count': c['member_count'] ?? 0,
    'pet_count': c['pet_count'] ?? 0,
    'created_at': c['created_at']?.toString(),
    'updated_at': c['updated_at']?.toString(),
  };
}
