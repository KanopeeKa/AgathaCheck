import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const serverRoot = process.env.GOVERNANCE_FIXTURE_SERVER_ROOT
  ? path.resolve(process.env.GOVERNANCE_FIXTURE_SERVER_ROOT)
  : path.resolve(__dirname, '../../');

const SCAN_ROOTS = ['lib', 'services'];
const ROUTES_IMPORT_RE = /from\s+['"][^'"]*\/routes\//;
const ROUTES_IMPORT_RE_ALT = /require\s*\(\s*['"][^'"]*\/routes\//;

const ROUTE_SCAN_EXCLUDED = [
  'routes/fosterPlacements.js',
  'routes/custodyTransfers.js',
];

const IMPORT_SPEC_RE = /(?:from|export\s+\*\s+from)\s+['"]([^'"]+)['"]/g;

function posixRelative(filePath) {
  return path.relative(serverRoot, filePath).split(path.sep).join('/');
}

function collectJsFiles(dir, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === 'node_modules') continue;
      collectJsFiles(full, out);
      continue;
    }
    if (entry.name.endsWith('.js')) out.push(full);
  }
  return out;
}

function importsRoutesModule(source) {
  return ROUTES_IMPORT_RE.test(source) || ROUTES_IMPORT_RE_ALT.test(source);
}

function isExcludedRouteFile(rel) {
  if (ROUTE_SCAN_EXCLUDED.includes(rel)) return true;
  if (rel.startsWith('routes/organizations/')) return true;
  return false;
}

function routeAreaKey(relPath) {
  const parts = relPath.replace(/^routes\//, '').split('/');
  if (parts.length === 1) {
    return parts[0].replace(/\.js$/, '');
  }
  if (parts[0] === 'organizations' && parts[1] === 'placements') {
    return 'organizations/placements';
  }
  return parts[0];
}

function resolveRouteImport(fromRel, spec) {
  if (!spec.startsWith('.')) return null;
  const resolved = path.normalize(path.join(path.dirname(fromRel), spec)).split(path.sep).join('/');
  if (!resolved.startsWith('routes/') || !resolved.endsWith('.js')) return null;
  return resolved;
}

function isAllowedCrossAreaRouteTarget(resolved) {
  const base = path.basename(resolved);
  return base === 'index.js' || base === 'shared.js';
}

function scanCrossAreaRouteImports() {
  const violations = [];
  const routesDir = path.join(serverRoot, 'routes');
  for (const file of collectJsFiles(routesDir)) {
    const rel = posixRelative(file);
    if (isExcludedRouteFile(rel)) continue;
    const importerArea = routeAreaKey(rel);
    const source = fs.readFileSync(file, 'utf8');
    let match;
    IMPORT_SPEC_RE.lastIndex = 0;
    while ((match = IMPORT_SPEC_RE.exec(source))) {
      const resolved = resolveRouteImport(rel, match[1]);
      if (!resolved || isExcludedRouteFile(resolved)) continue;
      const targetArea = routeAreaKey(resolved);
      if (targetArea === importerArea) continue;
      if (isAllowedCrossAreaRouteTarget(resolved)) continue;
      violations.push(`${rel} → ${resolved} (via ${match[1]})`);
    }
  }
  return violations;
}

const DB_FORBIDDEN_IMPORT_RE = /from\s+['"]([^'"]+)['"]/g;

function isDbQueryModule(rel) {
  if (!rel.startsWith('db/')) return false;
  if (rel.startsWith('db/seeds/')) return false;
  if (rel.startsWith('db/migrations/')) return false;
  if (rel.startsWith('db/schema/')) return false;
  return true;
}

function isForbiddenDbImportTarget(spec) {
  const normalized = spec.replace(/^\.\.\//, '');
  if (normalized.startsWith('../lib/') || normalized.includes('/lib/')) return true;
  if (normalized.startsWith('../services/') || normalized.includes('/services/')) return true;
  if (normalized.startsWith('../routes/') || normalized.includes('/routes/')) return true;
  if (spec.startsWith('../../lib/') || spec.startsWith('../../services/') || spec.startsWith('../../routes/')) {
    return true;
  }
  return false;
}

function scanDbLayerImports() {
  const violations = [];
  const dbDir = path.join(serverRoot, 'db');
  for (const file of collectJsFiles(dbDir)) {
    const rel = posixRelative(file);
    if (!isDbQueryModule(rel)) continue;
    const source = fs.readFileSync(file, 'utf8');
    let match;
    DB_FORBIDDEN_IMPORT_RE.lastIndex = 0;
    while ((match = DB_FORBIDDEN_IMPORT_RE.exec(source))) {
      const spec = match[1];
      if (!spec.startsWith('.')) continue;
      if (isForbiddenDbImportTarget(spec)) {
        violations.push(`${rel} imports ${spec}`);
      }
    }
  }
  return violations;
}

const POOL_CONNECT_RE = /pool\.connect\s*\(/;

function scanRoutePoolConnect() {
  const violations = [];
  const routesDir = path.join(serverRoot, 'routes');
  for (const file of collectJsFiles(routesDir)) {
    const rel = posixRelative(file);
    if (isExcludedRouteFile(rel)) continue;
    const source = fs.readFileSync(file, 'utf8');
    if (POOL_CONNECT_RE.test(source)) {
      violations.push(rel);
    }
  }
  return violations;
}

describe('server direction — lib/services must not import routes', () => {
  it('has no server/lib or server/services imports from server/routes', () => {
    const violations = [];
    for (const root of SCAN_ROOTS) {
      const abs = path.join(serverRoot, root);
      for (const file of collectJsFiles(abs)) {
        const rel = posixRelative(file);
        const source = fs.readFileSync(file, 'utf8');
        if (importsRoutesModule(source)) {
          violations.push(rel);
        }
      }
    }
    expect(violations).toEqual([]);
  });
});

describe('server direction — route composition', () => {
  it('imports other route areas only through index.js or shared.js', () => {
    expect(scanCrossAreaRouteImports()).toEqual([]);
  });
});

describe('server direction — db query modules', () => {
  it('does not import lib, services, or routes', () => {
    expect(scanDbLayerImports()).toEqual([]);
  });
});

describe('server direction — route transactions', () => {
  it('does not call pool.connect() in active route modules', () => {
    expect(scanRoutePoolConnect()).toEqual([]);
  });
});
