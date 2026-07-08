import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import 'calendar_date.dart';
import 'jwt_secret.dart';
import 'routes_pool.dart';

const jsonHeaders = {'Content-Type': 'application/json'};

const petColorPalette = [
  0xFF7E57C2,
  0xFF9575CD,
  0xFF5C6BC0,
  0xFF7986CB,
  0xFF4DB6AC,
  0xFF81C784,
  0xFF4FC3F7,
  0xFFBA68C8,
  0xFFF06292,
  0xFFE57373,
  0xFFFFB74D,
  0xFFA1887F,
  0xFF90A4AE,
  0xFF64B5F6,
  0xFFAED581,
];

int? resolveColorValue(dynamic raw) {
  if (raw == null) return null;
  final v = raw is int ? raw : int.tryParse(raw.toString());
  if (v == null) return null;
  if (v < petColorPalette.length) return petColorPalette[v];
  return v;
}

Map<String, dynamic> petRowToMap(ResultRow row) {
  final c = row.toColumnMap();
  return {
    'id': c['id']?.toString(),
    'user_id': c['user_id']?.toString(),
    'name': c['name'],
    'species': c['species'],
    'breed': c['breed'] ?? '',
    'age': c['age'],
    'dateOfBirth': dateToIsoDate(c['date_of_birth']),
    'date_of_birth': dateToIsoDate(c['date_of_birth']),
    'weight': c['weight'],
    'gender': c['gender'],
    'bio': c['bio'] ?? '',
    'insurance': c['insurance'] ?? '',
    'neuteredDate': dateToIsoDate(c['neutered_date']),
    'neuterDismissed': c['neuter_dismissed'] ?? false,
    'chipId': c['chip_id'] ?? '',
    'chipDismissed': c['chip_dismissed'] ?? false,
    'photoPath': c['photo_path'],
    'vetId': c['vet_id']?.toString(),
    'colorValue': resolveColorValue(c['color_index']),
    'passedAway': c['passed_away'] ?? false,
    'organization_id': c['organization_id'],
    'created_at': c['created_at']?.toString(),
    'updated_at': c['updated_at']?.toString(),
  };
}

Map<String, dynamic> vetRowToMap(ResultRow row) {
  final c = row.toColumnMap();
  return {
    'id': c['id']?.toString(),
    'user_id': c['user_id']?.toString(),
    'name': c['name'],
    'clinic': c['clinic'],
    'phone': c['phone'],
    'email': c['email'],
    'website': c['website'] ?? '',
    'address': c['address'] ?? '',
    'notes': c['notes'] ?? '',
    'created_at': c['created_at']?.toString(),
    'updated_at': c['updated_at']?.toString(),
  };
}

Future<void> autoAssignColors(List<Map<String, dynamic>> pets) async {
  final usedColors = <int>{};
  for (final p in pets) {
    if (p['colorValue'] != null) usedColors.add(p['colorValue'] as int);
  }
  for (final p in pets) {
    if (p['colorValue'] == null) {
      int color = petColorPalette[0];
      for (final c in petColorPalette) {
        if (!usedColors.contains(c)) {
          color = c;
          break;
        }
      }
      usedColors.add(color);
      p['colorValue'] = color;
      try {
        await pool.execute(
          Sql.named('UPDATE pets SET color_index = @color WHERE id = @id'),
          parameters: {'color': color, 'id': p['id']},
        );
      } catch (_) {}
    }
  }
}

Future<bool> userInOrg(Object orgId, Object userId) async {
  final result = await pool.execute(
    Sql.named(
        'SELECT 1 FROM organization_users WHERE organization_id = @orgId AND user_id = @userId LIMIT 1'),
    parameters: {'orgId': orgId, 'userId': userId},
  );
  return result.isNotEmpty;
}

Response notImplemented() => Response(501,
    body: jsonEncode({'error': 'Not implemented'}), headers: jsonHeaders);

String? extractUserId(Request request) {
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
