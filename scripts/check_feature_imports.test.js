'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { test } = require('node:test');

const { stronglyConnected } = require('./check_feature_imports');

const SCRIPT = path.join(__dirname, 'check_feature_imports.js');
const FIXTURE = path.join(__dirname, 'test/fixtures/feature-imports/base');

function write(root, rel, text) {
  const file = path.join(root, rel);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, text);
}

/**
 * Copy the base fixture Dart tree into a temp dir so each test can mutate it.
 * pubspec and frozen manifest are generated here (not committed) so repo tooling
 * never mistakes the fixture for a real package.
 */
function makeRepo() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'feature-imports-'));
  fs.cpSync(FIXTURE, root, { recursive: true });
  write(root, 'flutter_app/pubspec.yaml', 'name: fixture_app\n');
  write(root, 'docs/engineering/frozen-domains/manifest.json', JSON.stringify({
    sourceRoots: ['flutter_app/lib/features/organization'],
    activeSurfacesToRemove: ['flutter_app/lib/features/pet_care/presentation/removed_surface.dart'],
  }));
  return root;
}

function remove(root, rel) {
  fs.rmSync(path.join(root, rel));
}

function run(root, ...args) {
  const res = spawnSync(process.execPath, [SCRIPT, '--root', root, ...args], { encoding: 'utf8' });
  return { code: res.status, out: `${res.stdout}${res.stderr}` };
}

function baseline(root) {
  return JSON.parse(fs.readFileSync(path.join(root, 'scripts/feature-import-baseline.json'), 'utf8'));
}

function initRepo() {
  const root = makeRepo();
  assert.equal(run(root, '--init').code, 0);
  return root;
}

const LIB = 'flutter_app/lib/features';

test('init baselines existing violations by identity and passes', () => {
  const root = initRepo();
  const data = baseline(root);
  assert.ok(data.violations.includes(
    `R1|${LIB}/pet_profile/presentation/profile.dart|${LIB}/experience/presentation/shell.dart`,
  ));
  assert.ok(data.edges.includes('pet_profile->experience'));
  assert.equal(run(root).code, 0);
});

test('R1: a domain feature importing experience fails', () => {
  const root = initRepo();
  write(root, `${LIB}/vet/presentation/vet_card.dart`,
    "import 'package:fixture_app/features/experience/presentation/shell.dart';\n");
  const res = run(root);
  assert.equal(res.code, 1);
  assert.match(res.out, /NEW R1\|flutter_app\/lib\/features\/vet\/presentation\/vet_card\.dart/);
});

test('R2: a relative import of another feature data layer fails', () => {
  const root = initRepo();
  write(root, `${LIB}/pet_profile/domain/reader.dart`, "import '../../vet/data/vet_store.dart';\n");
  const res = run(root);
  assert.equal(res.code, 1);
  assert.match(res.out, /NEW R2\|flutter_app\/lib\/features\/pet_profile\/domain\/reader\.dart\|flutter_app\/lib\/features\/vet\/data\/vet_store\.dart/);
});

test('R3: export of another feature presentation fails, composition layer is exempt', () => {
  const root = initRepo();
  write(root, `${LIB}/pet_profile/pet_profile.dart`,
    "export 'package:fixture_app/features/vet/presentation/vet_card.dart';\n");
  write(root, `${LIB}/experience/presentation/vets_tab.dart`,
    "import 'package:fixture_app/features/vet/presentation/vet_card.dart';\n");
  write(root, 'flutter_app/lib/core/router/routes.dart',
    "import 'package:fixture_app/features/vet/presentation/vet_card.dart';\n");
  const res = run(root);
  assert.equal(res.code, 1);
  assert.match(res.out, /NEW R3\|flutter_app\/lib\/features\/pet_profile\/pet_profile\.dart/);
  assert.doesNotMatch(res.out, /NEW R3\|flutter_app\/lib\/features\/experience/);
  assert.doesNotMatch(res.out, /NEW R3\|flutter_app\/lib\/core\/router/);
});

test('R4: a new feature edge fails even without a layer violation', () => {
  const root = initRepo();
  write(root, `${LIB}/vet/domain/vet.dart`,
    "import 'package:fixture_app/features/pet_profile/domain/pet.dart';\n");
  const res = run(root);
  assert.equal(res.code, 1);
  assert.match(res.out, /NEW R4\|vet->pet_profile/);
});

test('swapping one baselined violation for a different one still fails', () => {
  const root = initRepo();
  remove(root, `${LIB}/pet_profile/presentation/profile.dart`);
  write(root, `${LIB}/pet_profile/presentation/other.dart`,
    "import 'package:fixture_app/features/experience/presentation/shell.dart';\n");
  const res = run(root);
  assert.equal(res.code, 1);
  assert.match(res.out, /NEW R1\|flutter_app\/lib\/features\/pet_profile\/presentation\/other\.dart/);
  assert.match(res.out, /RESOLVED R1\|flutter_app\/lib\/features\/pet_profile\/presentation\/profile\.dart/);
});

test('stale entries fail until --update-baseline shrinks the baseline', () => {
  const root = initRepo();
  const before = baseline(root).violations.length;
  write(root, `${LIB}/health_tracking/domain/entry.dart`, '// no cross-feature imports\n');
  const stale = run(root);
  assert.equal(stale.code, 1);
  assert.match(stale.out, /RESOLVED R2\|flutter_app\/lib\/features\/health_tracking\/domain\/entry\.dart/);
  assert.equal(run(root, '--update-baseline').code, 0);
  assert.equal(baseline(root).violations.length, before - 1);
  assert.equal(run(root).code, 0);
});

test('--update-baseline refuses to add new violations', () => {
  const root = initRepo();
  write(root, `${LIB}/vet/presentation/vet_card.dart`,
    "import 'package:fixture_app/features/experience/presentation/shell.dart';\n");
  const res = run(root, '--update-baseline');
  assert.equal(res.code, 1);
  assert.match(res.out, /only removes entries/);
});

test('--accept-new records the reason for each accepted identity', () => {
  const root = initRepo();
  write(root, `${LIB}/vet/domain/vet.dart`,
    "import 'package:fixture_app/features/pet_profile/domain/pet.dart';\n");
  assert.equal(run(root, '--accept-new', 'approved in #123').code, 0);
  const data = baseline(root);
  assert.ok(data.edges.includes('vet->pet_profile'));
  assert.deepEqual(
    data.exceptions.map((x) => [x.identity, x.reason]),
    [['R4|vet->pet_profile', 'approved in #123']],
  );
  assert.equal(run(root).code, 0);
});

test('frozen roots, removed surfaces and generated files are ignored; part directives count', () => {
  const root = initRepo();
  const bad = "import 'package:fixture_app/features/experience/presentation/shell.dart';\n";
  write(root, `${LIB}/organization/presentation/org.dart`, bad);
  write(root, `${LIB}/vet/presentation/vet_card.g.dart`, bad);
  write(root, `${LIB}/pet_care/presentation/removed_surface.dart`, bad);
  assert.equal(run(root).code, 0);
  write(root, `${LIB}/vet/presentation/vet_part.dart`,
    "part 'package:fixture_app/features/experience/presentation/shell.dart';\n");
  const res = run(root);
  assert.equal(res.code, 1);
  assert.match(res.out, /NEW R1\|flutter_app\/lib\/features\/vet\/presentation\/vet_part\.dart/);
});

test('stronglyConnected reports only multi-feature components', () => {
  const comps = stronglyConnected(['a->b', 'b->a', 'b->c', 'c->d']);
  assert.deepEqual(comps, [['a', 'b']]);
});
