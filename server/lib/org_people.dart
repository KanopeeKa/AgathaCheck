import 'package:postgres/postgres.dart';

import 'foster_placements.dart';
import 'org_roles.dart';

int personCategoryRank(String? role, String kind) {
  if (kind == 'external') return 4;
  final r = normaliseOrgRole(role);
  if (r == orgRoleSuperAdmin || r == 'pending_$orgRoleSuperAdmin') return 1;
  if (r == orgRoleAdmin || r == 'pending_$orgRoleAdmin') return 2;
  return 3;
}

String personRef(String kind, String id) => '$kind:$id';

String _memberActiveCountSql(String aliasUserId, String aliasOrgId) => '''
  (
    SELECT COUNT(DISTINCT fpl.pet_id)::int
    FROM foster_placements fpl
    WHERE fpl.organization_id = $aliasOrgId
      AND fpl.foster_user_id = $aliasUserId
      AND fpl.status IN (${fosterActiveStatusesSql()})
  )
''';

String _externalActiveCountSql(String aliasFpId, String aliasOrgId) => '''
  (
    SELECT COUNT(DISTINCT fpl.pet_id)::int
    FROM foster_placements fpl
    WHERE fpl.organization_id = $aliasOrgId
      AND fpl.org_foster_parent_id = $aliasFpId
      AND fpl.status IN (${fosterActiveStatusesSql()})
  )
''';

Map<String, dynamic> personSummaryToMap(Map<String, dynamic> row) {
  return {
    'id': personRef(row['kind'].toString(), row['record_id'].toString()),
    'kind': row['kind'],
    'record_id': row['record_id']?.toString(),
    'user_id': row['user_id']?.toString(),
    'display_name': (row['display_name']?.toString() ?? '').trim().isNotEmpty
        ? (row['display_name']?.toString() ?? '').trim()
        : row['email'],
    'email': row['email'],
    'role': row['role'] != null ? normaliseOrgRole(row['role']?.toString()) : null,
    'photo_url': row['photo_url'],
    'is_pending': row['is_pending'] == true,
    'is_primary_contact': row['is_primary_contact'] == true,
    'active_foster_count': int.tryParse(row['active_foster_count']?.toString() ?? '') ?? 0,
    'category_rank': row['category_rank'],
  };
}

Map<String, dynamic> personDetailToMap(
  Map<String, dynamic> row, {
  List<dynamic> currentPlacements = const [],
  List<dynamic> pastPlacements = const [],
}) {
  return {
    ...personSummaryToMap(row),
    'foster_phone': row['foster_phone']?.toString() ?? '',
    'foster_address': row['foster_address']?.toString() ?? '',
    'admin_notes': row['admin_notes']?.toString() ?? '',
    'current_placements': currentPlacements,
    'past_placements': pastPlacements,
  };
}

Future<List<Map<String, dynamic>>> listOrgPeople(
  Pool pool,
  String orgId,
) async {
  final orgResult = await pool.execute(
    Sql.named('SELECT primary_contact_ref FROM organizations WHERE id = @orgId'),
    parameters: {'orgId': orgId},
  );
  final primaryContactRef = orgResult.isEmpty
      ? null
      : orgResult.first.toColumnMap()['primary_contact_ref']?.toString();

  final memberResult = await pool.execute(
    Sql('''
      SELECT 'member' AS kind,
             ou.id AS record_id,
             u.id AS user_id,
             TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS display_name,
             u.email,
             u.photo_url,
             ou.role,
             (ou.role LIKE 'pending_%') AS is_pending,
             ${_memberActiveCountSql('u.id', 'ou.organization_id')} AS active_foster_count
      FROM organization_users ou
      JOIN users u ON u.id = ou.user_id
      WHERE ou.organization_id = @orgId
      ORDER BY display_name, u.email
    '''),
    parameters: {'orgId': orgId},
  );

  final externalResult = await pool.execute(
    Sql('''
      SELECT 'external' AS kind,
             fp.id AS record_id,
             fp.user_id,
             fp.display_name,
             fp.email,
             NULL::text AS photo_url,
             NULL::varchar AS role,
             false AS is_pending,
             ${_externalActiveCountSql('fp.id', 'fp.organization_id')} AS active_foster_count
      FROM org_foster_parents fp
      WHERE fp.organization_id = @orgId
      ORDER BY fp.display_name, fp.email
    '''),
    parameters: {'orgId': orgId},
  );

  final combined = <Map<String, dynamic>>[
    ...memberResult.map((r) => r.toColumnMap()),
    ...externalResult.map((r) => r.toColumnMap()),
  ].map((row) {
    final kind = row['kind'].toString();
    final recordId = row['record_id'].toString();
    return {
      ...row,
      'category_rank': personCategoryRank(row['role']?.toString(), kind),
      'is_primary_contact': primaryContactRef == personRef(kind, recordId),
    };
  }).toList();

  combined.sort((a, b) {
    final rankA = a['category_rank'] as int;
    final rankB = b['category_rank'] as int;
    if (rankA != rankB) return rankA.compareTo(rankB);
    final countA = int.tryParse(a['active_foster_count']?.toString() ?? '') ?? 0;
    final countB = int.tryParse(b['active_foster_count']?.toString() ?? '') ?? 0;
    if (countA != countB) return countB.compareTo(countA);
    final nameA = (a['display_name'] ?? a['email'] ?? '').toString().toLowerCase();
    final nameB = (b['display_name'] ?? b['email'] ?? '').toString().toLowerCase();
    return nameA.compareTo(nameB);
  });

  return combined.map(personSummaryToMap).toList();
}

String computePlacementOutcome(
  Map<String, dynamic> placement,
  bool petPassedAway,
  bool fosteredElsewhere,
) {
  if (petPassedAway) return 'passed_away';
  if (placement['status'] == placementStatusAdopted) return 'adopted';
  if (fosteredElsewhere) return 'in_foster_elsewhere';
  return 'not_in_foster';
}

Future<Map<String, List<Map<String, dynamic>>>> _loadPersonPlacements(
  Pool pool,
  String orgId,
  String kind,
  String? userId,
  String? externalId,
) async {
  final placementFilter = kind == 'member'
      ? 'fp.foster_user_id = @recordRef'
      : 'fp.org_foster_parent_id = @recordRef';
  final recordRef = kind == 'member' ? userId : externalId;

  final result = await pool.execute(
    Sql('''
      SELECT fp.*,
             p.name AS pet_name,
             p.species AS pet_species,
             p.passed_away AS pet_passed_away,
             o.name AS organization_name,
             TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS foster_name,
             u.email AS foster_email
      FROM foster_placements fp
      JOIN pets p ON p.id = fp.pet_id
      JOIN organizations o ON o.id = fp.organization_id
      LEFT JOIN users u ON u.id = fp.foster_user_id
      WHERE fp.organization_id = @orgId
        AND $placementFilter
      ORDER BY fp.start_date DESC NULLS LAST, fp.created_at DESC
    '''),
    parameters: {'orgId': orgId, 'recordRef': recordRef},
  );

  final openByPet = await pool.execute(
    Sql('''
      SELECT DISTINCT ON (pet_id) pet_id, foster_user_id, org_foster_parent_id, status
      FROM foster_placements
      WHERE organization_id = @orgId
        AND status IN (${openPlacementStatusesSql()})
      ORDER BY pet_id, created_at DESC
    '''),
    parameters: {'orgId': orgId},
  );
  final openMap = <String, Map<String, dynamic>>{
    for (final row in openByPet)
      row.toColumnMap()['pet_id'].toString(): row.toColumnMap(),
  };

  final current = <Map<String, dynamic>>[];
  final past = <Map<String, dynamic>>[];

  for (final raw in result) {
    final row = raw.toColumnMap();
    final petId = row['pet_id'].toString();
    final open = openMap[petId];
    var fosteredElsewhere = false;
    if (open != null && row['status'] != open['status']) {
      if (kind == 'member') {
        fosteredElsewhere = open['foster_user_id']?.toString() != userId;
      } else {
        fosteredElsewhere = open['org_foster_parent_id']?.toString() != externalId;
      }
    } else if (!openPlacementStatuses.contains(row['status'])) {
      final currentOpen = openMap[petId];
      if (currentOpen != null) {
        if (kind == 'member') {
          fosteredElsewhere = currentOpen['foster_user_id']?.toString() != userId;
        } else {
          fosteredElsewhere =
              currentOpen['org_foster_parent_id']?.toString() != externalId;
        }
      }
    }

    final base = placementToMap(row);
    if (openPlacementStatuses.contains(row['status'])) {
      current.add(base);
    } else {
      past.add({
        ...base,
        'outcome': computePlacementOutcome(
          row,
          row['pet_passed_away'] == true,
          fosteredElsewhere,
        ),
      });
    }
  }

  return {'current': current, 'past': past};
}

Future<Map<String, dynamic>?> getOrgPersonDetail(
  Pool pool,
  String orgId,
  String kind,
  String recordId,
) async {
  final orgResult = await pool.execute(
    Sql.named('SELECT primary_contact_ref FROM organizations WHERE id = @orgId'),
    parameters: {'orgId': orgId},
  );
  final primaryContactRef = orgResult.isEmpty
      ? null
      : orgResult.first.toColumnMap()['primary_contact_ref']?.toString();

  if (kind == 'member') {
    final result = await pool.execute(
      Sql('''
        SELECT 'member' AS kind,
               ou.id AS record_id,
               u.id AS user_id,
               TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS display_name,
               u.email,
               u.photo_url,
               ou.role,
               (ou.role LIKE 'pending_%') AS is_pending,
               COALESCE(ou.foster_phone, '') AS foster_phone,
               COALESCE(ou.foster_address, '') AS foster_address,
               COALESCE(ou.admin_notes, '') AS admin_notes,
               ${_memberActiveCountSql('u.id', 'ou.organization_id')} AS active_foster_count
        FROM organization_users ou
        JOIN users u ON u.id = ou.user_id
        WHERE ou.organization_id = @orgId AND ou.id = @recordId
      '''),
      parameters: {'orgId': orgId, 'recordId': recordId},
    );
    if (result.isEmpty) return null;
    final row = result.first.toColumnMap();
    row['is_primary_contact'] =
        primaryContactRef == personRef('member', recordId);
    final placements = await _loadPersonPlacements(
      pool,
      orgId,
      'member',
      row['user_id']?.toString(),
      null,
    );
    return personDetailToMap(
      row,
      currentPlacements: placements['current']!,
      pastPlacements: placements['past']!,
    );
  }

  final result = await pool.execute(
    Sql('''
      SELECT 'external' AS kind,
             fp.id AS record_id,
             fp.user_id,
             fp.display_name,
             fp.email,
             NULL::text AS photo_url,
             NULL::varchar AS role,
             false AS is_pending,
             COALESCE(fp.phone, '') AS foster_phone,
             COALESCE(fp.foster_address, '') AS foster_address,
             COALESCE(fp.notes, '') AS admin_notes,
             ${_externalActiveCountSql('fp.id', 'fp.organization_id')} AS active_foster_count
      FROM org_foster_parents fp
      WHERE fp.organization_id = @orgId AND fp.id = @recordId
    '''),
    parameters: {'orgId': orgId, 'recordId': recordId},
  );
  if (result.isEmpty) return null;
  final row = result.first.toColumnMap();
  final placements = await _loadPersonPlacements(
    pool,
    orgId,
    'external',
    null,
    recordId,
  );
  return personDetailToMap(
    row,
    currentPlacements: placements['current']!,
    pastPlacements: placements['past']!,
  );
}

Future<bool> updateOrgPersonContact(
  Pool pool,
  String orgId,
  String kind,
  String recordId,
  Map<String, dynamic> data,
) async {
  final fosterPhone =
      (data['foster_phone'] ?? data['fosterPhone'] ?? '').toString().trim();
  final fosterAddress =
      (data['foster_address'] ?? data['fosterAddress'] ?? '').toString().trim();
  final adminNotes =
      (data['admin_notes'] ?? data['adminNotes'] ?? '').toString().trim();

  if (kind == 'member') {
    final result = await pool.execute(
      Sql.named('''
        UPDATE organization_users
        SET foster_phone = @fosterPhone,
            foster_address = @fosterAddress,
            admin_notes = @adminNotes,
            updated_at = NOW()
        WHERE organization_id = @orgId AND id = @recordId
        RETURNING id
      '''),
      parameters: {
        'fosterPhone': fosterPhone,
        'fosterAddress': fosterAddress,
        'adminNotes': adminNotes,
        'orgId': orgId,
        'recordId': recordId,
      },
    );
    return result.isNotEmpty;
  }

  final displayName =
      (data['display_name'] ?? data['displayName'] ?? '').toString().trim();
  final email = (data['email'] ?? '').toString().trim();
  if (displayName.isEmpty) {
    throw OrgPeopleValidationException('Display name is required');
  }

  final result = await pool.execute(
    Sql.named('''
      UPDATE org_foster_parents
      SET display_name = @displayName,
          email = @email,
          phone = @fosterPhone,
          foster_address = @fosterAddress,
          notes = @adminNotes,
          updated_at = NOW()
      WHERE organization_id = @orgId AND id = @recordId
      RETURNING id
    '''),
    parameters: {
      'displayName': displayName,
      'email': email.isEmpty ? null : email,
      'fosterPhone': fosterPhone,
      'fosterAddress': fosterAddress,
      'adminNotes': adminNotes,
      'orgId': orgId,
      'recordId': recordId,
    },
  );
  return result.isNotEmpty;
}

class OrgPeopleValidationException implements Exception {
  OrgPeopleValidationException(this.message);
  final String message;
}
