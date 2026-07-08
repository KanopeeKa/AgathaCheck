import 'package:postgres/postgres.dart';

import '../../foster_placements.dart';

const placementDetailSelect = '''
    SELECT fp.*,
           p.name AS pet_name,
           p.species AS pet_species,
           o.name AS organization_name,
           TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS foster_name,
           u.email AS foster_email
  ''';

Future<List<Map<String, dynamic>>> loadPlacementRows(
  Pool pool,
  String sql,
  Map<String, dynamic> parameters,
) async {
  final results = await pool.execute(Sql.named(sql), parameters: parameters);
  return results.map((r) => placementToMap(r.toColumnMap())).toList();
}
