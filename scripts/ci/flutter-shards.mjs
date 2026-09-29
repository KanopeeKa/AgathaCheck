#!/usr/bin/env node
/**
 * Flutter CI shard manifest helper — single source of truth is
 * flutter_app/test/ci_shards.json (shard id → test roots).
 *
 * Every active `*_test.dart` must be owned by exactly one shard, or live under a
 * frozen root (docs/engineering/frozen-domains/manifest.json testRoots) or an
 * excluded root (e.g. the integration dir, which flutter-integration runs).
 *
 * Usage:
 *   node scripts/ci/flutter-shards.mjs list [--json]   # shard ids (JSON array with --json)
 *   node scripts/ci/flutter-shards.mjs files <shard>   # test files for one shard (flutter_app-relative)
 *   node scripts/ci/flutter-shards.mjs check           # fail on unowned / multiply-owned test files
 *   node scripts/ci/flutter-shards.mjs summary         # file counts per shard
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const FLUTTER_ROOT = path.join(REPO_ROOT, 'flutter_app');
export const MANIFEST_PATH = path.join(FLUTTER_ROOT, 'test', 'ci_shards.json');
const FROZEN_MANIFEST_PATH = path.join(
  REPO_ROOT,
  'docs',
  'engineering',
  'frozen-domains',
  'manifest.json',
);

/** Paths inside the manifest are relative to flutter_app/. */
function normalizeRoot(root) {
  return root.replace(/^flutter_app\//, '').replace(/\/+$/, '');
}

function isUnder(file, root) {
  return file === root || file.startsWith(`${root}/`);
}

export function loadManifest(manifestPath = MANIFEST_PATH) {
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  if (!Array.isArray(manifest.shards) || manifest.shards.length === 0) {
    throw new Error(`${manifestPath}: "shards" must be a non-empty array`);
  }
  const ids = new Set();
  for (const shard of manifest.shards) {
    if (!/^[a-z][a-z0-9-]*$/.test(shard.id || '')) {
      throw new Error(`${manifestPath}: invalid shard id ${JSON.stringify(shard.id)}`);
    }
    if (ids.has(shard.id)) throw new Error(`${manifestPath}: duplicate shard id ${shard.id}`);
    ids.add(shard.id);
    if (!Array.isArray(shard.roots) || shard.roots.length === 0) {
      throw new Error(`${manifestPath}: shard ${shard.id} needs at least one root`);
    }
    shard.roots = shard.roots.map(normalizeRoot);
  }
  manifest.excludedRoots = (manifest.excludedRoots || []).map(normalizeRoot);
  return manifest;
}

export function loadFrozenTestRoots(frozenPath = FROZEN_MANIFEST_PATH) {
  if (!fs.existsSync(frozenPath)) return [];
  const frozen = JSON.parse(fs.readFileSync(frozenPath, 'utf8'));
  return (frozen.testRoots || [])
    .filter((root) => root.startsWith('flutter_app/'))
    .map(normalizeRoot);
}

/** All `*_test.dart` files under flutter_app/test, flutter_app-relative, sorted. */
export function listTestFiles(root = FLUTTER_ROOT) {
  const out = [];
  const walk = (dir) => {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const abs = path.join(dir, entry.name);
      if (entry.isDirectory()) walk(abs);
      else if (entry.name.endsWith('_test.dart')) out.push(path.relative(root, abs).split(path.sep).join('/'));
    }
  };
  walk(path.join(root, 'test'));
  return out.sort();
}

/**
 * Classify one test file.
 * @returns {{kind: 'shard', shard: string} | {kind: 'frozen'} | {kind: 'excluded'} |
 *   {kind: 'unowned'} | {kind: 'multi', shards: string[]}}
 */
export function classifyTestFile(file, manifest, frozenRoots) {
  if (manifest.excludedRoots.some((root) => isUnder(file, root))) return { kind: 'excluded' };
  if (frozenRoots.some((root) => isUnder(file, root))) return { kind: 'frozen' };
  const owners = manifest.shards
    .filter((shard) => shard.roots.some((root) => isUnder(file, root)))
    .map((shard) => shard.id);
  if (owners.length === 0) return { kind: 'unowned' };
  if (owners.length > 1) return { kind: 'multi', shards: owners };
  return { kind: 'shard', shard: owners[0] };
}

export function buildOwnership({ manifest, frozenRoots, files }) {
  const byShard = new Map(manifest.shards.map((shard) => [shard.id, []]));
  const unowned = [];
  const multi = [];
  let frozen = 0;
  let excluded = 0;
  for (const file of files) {
    const result = classifyTestFile(file, manifest, frozenRoots);
    if (result.kind === 'shard') byShard.get(result.shard).push(file);
    else if (result.kind === 'unowned') unowned.push(file);
    else if (result.kind === 'multi') multi.push({ file, shards: result.shards });
    else if (result.kind === 'frozen') frozen += 1;
    else excluded += 1;
  }
  return { byShard, unowned, multi, frozen, excluded };
}

function loadDefaultOwnership() {
  const manifest = loadManifest();
  return { manifest, ...buildOwnership({ manifest, frozenRoots: loadFrozenTestRoots(), files: listTestFiles() }) };
}

function main(argv) {
  const [cmd, arg] = argv;
  if (cmd === 'list') {
    const ids = loadManifest().shards.map((shard) => shard.id);
    console.log(argv.includes('--json') ? JSON.stringify(ids) : ids.join('\n'));
    return 0;
  }
  if (cmd === 'files') {
    const { byShard } = loadDefaultOwnership();
    if (!byShard.has(arg)) {
      console.error(`::error::Unknown Flutter shard '${arg}' (see flutter_app/test/ci_shards.json)`);
      return 1;
    }
    const files = byShard.get(arg);
    if (files.length === 0) {
      console.error(`::error::Flutter shard '${arg}' owns no test files`);
      return 1;
    }
    console.log(files.join('\n'));
    return 0;
  }
  if (cmd === 'summary' || cmd === 'check') {
    const { byShard, unowned, multi, frozen, excluded } = loadDefaultOwnership();
    for (const [id, files] of byShard) console.log(`${id}: ${files.length} test files`);
    console.log(`frozen roots: ${frozen} · excluded roots: ${excluded}`);
    if (cmd === 'summary') return 0;
    let failed = false;
    for (const file of unowned) {
      console.error(`::error file=flutter_app/${file}::Test file is not owned by any CI shard — add its directory to flutter_app/test/ci_shards.json`);
      failed = true;
    }
    for (const { file, shards } of multi) {
      console.error(`::error file=flutter_app/${file}::Test file is owned by several shards (${shards.join(', ')}) — make roots disjoint`);
      failed = true;
    }
    for (const [id, files] of byShard) {
      if (files.length === 0) {
        console.error(`::error::Flutter shard '${id}' owns no test files — remove it or fix its roots`);
        failed = true;
      }
    }
    if (failed) return 1;
    console.log('flutter-shards check: OK — every active test file runs in exactly one CI shard');
    return 0;
  }
  console.error('usage: flutter-shards.mjs <list [--json] | files <shard> | check | summary>');
  return 1;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1])) {
  process.exit(main(process.argv.slice(2)));
}
