/**
 * Split organization_routes.dart into server/lib/organizations/
 * Run from server/: node scripts/split-dart-organization-routes.mjs
 */
import fs from 'fs';

const src = fs.readFileSync('lib/organization_routes.dart', 'utf8');
const lines = src.split('\n');

function sliceRanges(ranges) {
  return ranges
    .map(([start, end]) => lines.slice(start - 1, end).join('\n'))
    .join('\n\n');
}

function rename(body, pairs) {
  let out = body;
  for (const [from, to] of pairs) {
    out = out.replaceAll(from, to);
  }
  return out;
}

const outDir = 'lib/organizations';
fs.mkdirSync(outDir, { recursive: true });

const shared = `import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../http_security.dart';
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
`;

fs.writeFileSync(`${outDir}/org_shared.dart`, shared);

const commonRenames = [
  ['_extractUserId', 'extractOrgUserId'],
  ['_getMemberRole', 'getOrgMemberRole'],
  ['_isActiveMember', 'isActiveOrgMember'],
  ['_isAdmin', 'isOrgAdmin'],
  ['_forbidden', 'orgForbidden'],
  ['_orgToMap', 'orgRowToMap'],
  ['_jsonHeaders', 'orgJsonHeaders'],
  ['_assignableRoles', 'assignableOrgRoles'],
  ['_uuid.v4()', 'orgUuid.v4()'],
];

function writeModule(file, fn, ranges, extraImports = '') {
  let body = rename(sliceRanges(ranges), commonRenames);
  const needsUuid = body.includes('orgUuid.v4()');
  const content = `import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
${needsUuid ? "import 'package:uuid/uuid.dart';\n" : ''}${extraImports}import '../http_security.dart';
import 'org_shared.dart';

void ${fn}(Router router, Pool pool) {
${needsUuid ? '  final orgUuid = Uuid();\n' : ''}${body
    .split('\n')
    .map((l) => `  ${l}`)
    .join('\n')}
}
`;
  fs.writeFileSync(`${outDir}/${file}`, content);
}

writeModule('invites_routes.dart', 'registerOrgInvitesRoutes', [[74, 144]]);
writeModule('core_routes.dart', 'registerOrgCoreRoutes', [
  [50, 72],
  [146, 269],
]);
writeModule('members_routes.dart', 'registerOrgMembersRoutes', [[271, 340]]);
writeModule('pets_routes.dart', 'registerOrgPetsRoutes', [[342, 388]]);

fs.writeFileSync(
  `${outDir}/organization_routes.dart`,
  `import 'package:postgres/postgres.dart';
import 'package:shelf_router/shelf_router.dart';

import 'core_routes.dart';
import 'invites_routes.dart';
import 'members_routes.dart';
import 'pets_routes.dart';

Router organizationRoutes(Pool pool) {
  final router = Router();
  registerOrgInvitesRoutes(router, pool);
  registerOrgCoreRoutes(router, pool);
  registerOrgMembersRoutes(router, pool);
  registerOrgPetsRoutes(router, pool);
  return router;
}

export 'org_shared.dart' show getOrgMemberRole, isOrgAdmin;
`,
);

fs.writeFileSync(
  'lib/organization_routes.dart',
  "export 'organizations/organization_routes.dart';\n",
);

fs.writeFileSync(
  `${outDir}/README.md`,
  `# Dart organization routes (Shelf)

Mirrors the Node module layout in \`server/routes/organizations/\`.
The Dart implementation currently covers a **subset** of Node routes
(foster parents, placements, and people directory are Node-only today).

| Module | Routes |
|--------|--------|
| \`org_shared.dart\` | Auth helpers, role guards, row mapping |
| \`invites_routes.dart\` | Pending invites, accept/decline |
| \`core_routes.dart\` | Org CRUD |
| \`members_routes.dart\` | Members list, invite |
| \`pets_routes.dart\` | Org pets, archived |
`,
);

console.log('Dart organization routes split complete.');
