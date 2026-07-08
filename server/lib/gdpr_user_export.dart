import 'package:postgres/postgres.dart';

/// GDPR Art. 15/20 export payload sections for GET /me/export (Dart Shelf).
Future<Map<String, List<Map<String, dynamic>>>> buildUserDataExport(
  Pool pool,
  String userId,
) async {
  final results = await Future.wait([
    pool.execute(
      Sql.named('SELECT * FROM pets WHERE user_id = @id'),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named('SELECT * FROM vets WHERE user_id = @id'),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named('SELECT * FROM health_entries WHERE user_id = @id'),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named('SELECT * FROM health_issues WHERE user_id = @id'),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named(
        'SELECT hh.* FROM health_history hh '
        'INNER JOIN health_entries he ON he.id = hh.health_entry_id '
        'WHERE he.user_id = @id',
      ),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named(
        'SELECT hep.* FROM health_event_photos hep '
        'INNER JOIN health_entries he ON he.id = hep.health_entry_id '
        'WHERE he.user_id = @id',
      ),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named('SELECT * FROM health_issue_events WHERE user_id = @id'),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named('SELECT * FROM weight_entries WHERE user_id = @id'),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named(
        'SELECT * FROM notifications WHERE user_id = @id ORDER BY created_at DESC',
      ),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named('SELECT * FROM notification_preferences WHERE user_id = @id'),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named('SELECT * FROM organization_users WHERE user_id = @id'),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named(
        'SELECT o.* FROM organizations o '
        'INNER JOIN organization_users ou ON ou.organization_id = o.id '
        'WHERE ou.user_id = @id',
      ),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named('SELECT * FROM pet_access WHERE user_id = @id'),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named('SELECT * FROM pet_share_links WHERE created_by = @id'),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named('SELECT * FROM shared_pets WHERE user_id = @id'),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named(
        'SELECT * FROM archived_pets '
        'WHERE user_id = @id OR transferred_to_user_id = @id',
      ),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named(
        'SELECT * FROM family_events '
        'WHERE user_id = @id OR assigned_to_user_id = @id OR created_by = @id',
      ),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named(
        'SELECT * FROM foster_placements '
        'WHERE foster_user_id = @id OR created_by = @id',
      ),
      parameters: {'id': userId},
    ),
    pool.execute(
      Sql.named('SELECT * FROM org_foster_parents WHERE user_id = @id'),
      parameters: {'id': userId},
    ),
  ]);

  List<Map<String, dynamic>> rows(Result result) =>
      result.map((r) => r.toColumnMap()).toList();

  return {
    'pets': rows(results[0]),
    'vets': rows(results[1]),
    'health_entries': rows(results[2]),
    'health_issues': rows(results[3]),
    'health_history': rows(results[4]),
    'health_event_photos': rows(results[5]),
    'health_issue_events': rows(results[6]),
    'weight_entries': rows(results[7]),
    'notifications': rows(results[8]),
    'notification_preferences': rows(results[9]),
    'organization_memberships': rows(results[10]),
    'organizations': rows(results[11]),
    'pet_access': rows(results[12]),
    'pet_share_links': rows(results[13]),
    'shared_pets': rows(results[14]),
    'archived_pets': rows(results[15]),
    'family_events': rows(results[16]),
    'foster_placements': rows(results[17]),
    'org_foster_parent_records': rows(results[18]),
  };
}

Map<String, int> exportAuditMetadata(Map<String, List<dynamic>> exportData) {
  return {
    'pet_count': exportData['pets']?.length ?? 0,
    'vet_count': exportData['vets']?.length ?? 0,
    'health_entry_count': exportData['health_entries']?.length ?? 0,
    'health_issue_count': exportData['health_issues']?.length ?? 0,
    'weight_entry_count': exportData['weight_entries']?.length ?? 0,
    'notification_count': exportData['notifications']?.length ?? 0,
    'organization_count': exportData['organizations']?.length ?? 0,
    'pet_access_count': exportData['pet_access']?.length ?? 0,
    'share_link_count': exportData['pet_share_links']?.length ?? 0,
  };
}
