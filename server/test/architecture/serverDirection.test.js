import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const serverRoot = path.resolve(__dirname, '../../');

const SCAN_ROOTS = ['lib', 'services'];
const ROUTES_IMPORT_RE = /from\s+['"][^'"]*\/routes\//;
const ROUTES_IMPORT_RE_ALT = /require\s*\(\s*['"][^'"]*\/routes\//;

/** Pre-existing; I2.4 extends this test to cover all lib → routes imports. */
const DEFERRED_ROUTE_IMPORT_VIOLATIONS = new Set([
  'lib/care/observations/weightObservationService.js',
]);

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

describe('server direction — lib/services must not import routes', () => {
  it('has no server/lib or server/services imports from server/routes', () => {
    const violations = [];
    for (const root of SCAN_ROOTS) {
      const abs = path.join(serverRoot, root);
      for (const file of collectJsFiles(abs)) {
        const rel = posixRelative(file);
        const source = fs.readFileSync(file, 'utf8');
        if (importsRoutesModule(source) && !DEFERRED_ROUTE_IMPORT_VIOLATIONS.has(rel)) {
          violations.push(rel);
        }
      }
    }
    expect(violations).toEqual([]);
  });
});
