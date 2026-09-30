#!/usr/bin/env node
/**
 * Cross-feature import gate for flutter_app/lib (D5/D6, active-codebase review).
 *
 * Baselines existing violations by stable identity and blocks new ones.
 * Rules:
 *   R1 domain-to-experience       a feature other than experience imports features/experience/**
 *   R2 cross-feature-data         anything outside feature X imports features/X/data/**
 *   R3 cross-feature-presentation anything outside feature X imports features/X/presentation/**
 *                                 (composition layer exempt: features/experience/**, core/router/**, lib/*.dart)
 *   R4 new-feature-edge           a feature → feature edge that is not in the baseline edge list
 *
 * Usage:
 *   node scripts/check_feature_imports.js                     # check against baseline
 *   node scripts/check_feature_imports.js --update-baseline   # drop resolved entries (ratchet down only)
 *   node scripts/check_feature_imports.js --accept-new "<reason>"   # human-approved exception
 *   node scripts/check_feature_imports.js --init              # create the baseline (refuses if it exists)
 *   node scripts/check_feature_imports.js --summary           # print counts only, exit 0
 * Options: --root <repo dir> (default: repo root), --baseline <file>
 */
'use strict';

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const RULES = {
  R1: 'domain-to-experience',
  R2: 'cross-feature-data',
  R3: 'cross-feature-presentation',
  R4: 'new-feature-edge',
};

const LIB = 'flutter_app/lib';
const DIRECTIVE = /^\s*(?:import|export|part)\s+['"]([^'"]+)['"]/gm;
const GENERATED_SUFFIXES = ['.g.dart', '.freezed.dart', '.mocks.dart'];
const COMPOSITION_PREFIXES = [`${LIB}/features/experience/`, `${LIB}/core/router/`];

function parseArgs(argv) {
  const opts = { root: path.resolve(__dirname, '..'), baseline: null, mode: 'check', reason: null };
  for (let i = 2; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--root') opts.root = path.resolve(argv[++i]);
    else if (arg === '--baseline') opts.baseline = path.resolve(argv[++i]);
    else if (arg === '--update-baseline') opts.mode = 'update';
    else if (arg === '--init') opts.mode = 'init';
    else if (arg === '--summary') opts.mode = 'summary';
    else if (arg === '--accept-new') {
      opts.mode = 'accept';
      opts.reason = argv[++i];
      if (!opts.reason || opts.reason.startsWith('--')) throw new Error('--accept-new requires a reason');
    } else throw new Error(`unknown argument: ${arg}`);
  }
  if (!opts.baseline) opts.baseline = path.join(opts.root, 'scripts/feature-import-baseline.json');
  return opts;
}

function readJson(file, fallback) {
  return fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, 'utf8')) : fallback;
}

function packageName(root) {
  const pubspec = path.join(root, 'flutter_app/pubspec.yaml');
  const match = fs.existsSync(pubspec) && /^name:\s*(\S+)/m.exec(fs.readFileSync(pubspec, 'utf8'));
  return match ? match[1] : null;
}

function under(p, prefix) {
  const clean = prefix.replace(/\/$/, '');
  return p === clean || p.startsWith(`${clean}/`);
}

function isGenerated(rel) {
  return GENERATED_SUFFIXES.some((s) => rel.endsWith(s)) || under(rel, `${LIB}/l10n`);
}

function walk(root, relDir, out) {
  const abs = path.join(root, relDir);
  if (!fs.existsSync(abs)) return out;
  for (const entry of fs.readdirSync(abs, { withFileTypes: true })) {
    const rel = `${relDir}/${entry.name}`;
    if (entry.isDirectory()) walk(root, rel, out);
    else if (entry.name.endsWith('.dart')) out.push(rel);
  }
  return out;
}

/** Owner of a lib path: `feature:<name>`, `core`, or `app` (lib root wiring). */
function ownerOf(rel) {
  const parts = rel.split('/');
  if (parts[2] === 'features' && parts.length >= 5) return `feature:${parts[3]}`;
  if (parts[2] === 'core') return 'core';
  return 'app';
}

function featureOf(rel) {
  const parts = rel.split('/');
  return parts[2] === 'features' && parts.length >= 5 ? parts[3] : null;
}

function resolveSpec(spec, importer, pkg) {
  if (pkg && spec.startsWith(`package:${pkg}/`)) return `${LIB}/${spec.slice(`package:${pkg}/`.length)}`;
  if (spec.startsWith('package:') || spec.startsWith('dart:')) return null;
  return path.posix.normalize(path.posix.join(path.posix.dirname(importer), spec));
}

function isComposition(rel) {
  if (COMPOSITION_PREFIXES.some((p) => rel.startsWith(p))) return true;
  return path.posix.dirname(rel) === LIB;
}

function classify(importer, target) {
  const targetFeature = featureOf(target);
  if (!targetFeature) return null;
  const importerFeature = featureOf(importer);
  if (importerFeature === targetFeature) return null;
  if (targetFeature === 'experience' && importerFeature && importerFeature !== 'experience') return 'R1';
  const layer = target.split('/')[4];
  if (layer === 'data') return 'R2';
  if (layer === 'presentation' && !isComposition(importer)) return 'R3';
  return null;
}

function scan(root) {
  const manifest = readJson(path.join(root, 'docs/engineering/frozen-domains/manifest.json'), {});
  const frozen = manifest.sourceRoots || [];
  const removed = new Set(manifest.activeSurfacesToRemove || []);
  const pkg = packageName(root);
  const files = walk(root, LIB, []).filter(
    (rel) => !isGenerated(rel) && !removed.has(rel) && !frozen.some((f) => under(rel, f)),
  );
  const violations = new Set();
  const edges = new Map();
  for (const importer of files) {
    const text = fs.readFileSync(path.join(root, importer), 'utf8');
    for (const match of text.matchAll(DIRECTIVE)) {
      const target = resolveSpec(match[1], importer, pkg);
      if (!target || !target.startsWith(`${LIB}/`)) continue;
      const rule = classify(importer, target);
      if (rule) violations.add(`${rule}|${importer}|${target}`);
      const from = featureOf(importer);
      const to = featureOf(target);
      if (from && to && from !== to) {
        const key = `${from}->${to}`;
        edges.set(key, (edges.get(key) || 0) + 1);
      }
    }
  }
  return { violations: [...violations].sort(), edges };
}

/** Tarjan SCC over the feature graph; returns components with more than one feature. */
function stronglyConnected(edgeKeys) {
  const graph = new Map();
  for (const key of edgeKeys) {
    const [a, b] = key.split('->');
    if (!graph.has(a)) graph.set(a, []);
    if (!graph.has(b)) graph.set(b, []);
    graph.get(a).push(b);
  }
  let index = 0;
  const stack = [];
  const meta = new Map();
  const out = [];
  const visit = (v) => {
    meta.set(v, { index, low: index, onStack: true });
    index += 1;
    stack.push(v);
    for (const w of graph.get(v)) {
      if (!meta.has(w)) {
        visit(w);
        meta.get(v).low = Math.min(meta.get(v).low, meta.get(w).low);
      } else if (meta.get(w).onStack) {
        meta.get(v).low = Math.min(meta.get(v).low, meta.get(w).index);
      }
    }
    if (meta.get(v).low === meta.get(v).index) {
      const comp = [];
      let w;
      do {
        w = stack.pop();
        meta.get(w).onStack = false;
        comp.push(w);
      } while (w !== v);
      if (comp.length > 1) out.push(comp.sort());
    }
  };
  for (const v of [...graph.keys()].sort()) if (!meta.has(v)) visit(v);
  return out;
}

function headSha(root) {
  try {
    return execFileSync('git', ['-C', root, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
  } catch {
    return null;
  }
}

function countByRule(ids) {
  const counts = { R1: 0, R2: 0, R3: 0 };
  for (const id of ids) counts[id.split('|')[0]] += 1;
  return counts;
}

function writeBaseline(file, data) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(data, null, 2)}\n`);
}

function printSummary(current, edgeKeys) {
  const counts = countByRule(current.violations);
  console.log(
    `check_feature_imports: R1=${counts.R1} R2=${counts.R2} R3=${counts.R3} ` +
      `feature edges=${edgeKeys.length}`,
  );
  const sccs = stronglyConnected(edgeKeys);
  for (const comp of sccs) console.log(`  SCC (${comp.length} features): ${comp.join(' ↔ ')}`);
}

function main() {
  const opts = parseArgs(process.argv);
  const current = scan(opts.root);
  const edgeKeys = [...current.edges.keys()].sort();

  if (opts.mode === 'summary') {
    printSummary(current, edgeKeys);
    return 0;
  }
  if (opts.mode === 'init') {
    if (fs.existsSync(opts.baseline)) {
      console.error('check_feature_imports: baseline exists — use --update-baseline or --accept-new');
      return 1;
    }
    writeBaseline(opts.baseline, {
      _comment:
        'Cross-feature import baseline (D6). Only shrinks: run --update-baseline after removing a violation. ' +
        'Adding requires --accept-new "<reason>" with human approval. See docs/architecture/modularity.md.',
      base_commit: headSha(opts.root),
      rules: RULES,
      violations: current.violations,
      edges: edgeKeys,
      exceptions: [],
    });
    printSummary(current, edgeKeys);
    console.log(`check_feature_imports: wrote ${path.relative(opts.root, opts.baseline)}`);
    return 0;
  }

  const baseline = readJson(opts.baseline, null);
  if (!baseline) {
    console.error(`check_feature_imports: missing baseline ${opts.baseline} (run --init once)`);
    return 1;
  }
  const baseViolations = new Set(baseline.violations);
  const baseEdges = new Set(baseline.edges);
  const newViolations = current.violations.filter((id) => !baseViolations.has(id));
  const newEdges = edgeKeys.filter((e) => !baseEdges.has(e)).map((e) => `R4|${e}`);
  const currentSet = new Set(current.violations);
  const staleViolations = baseline.violations.filter((id) => !currentSet.has(id));
  const staleEdges = baseline.edges.filter((e) => !current.edges.has(e));

  if (opts.mode === 'update' || opts.mode === 'accept') {
    const added = opts.mode === 'accept' ? [...newViolations, ...newEdges] : [];
    if (opts.mode === 'update' && (newViolations.length || newEdges.length)) {
      console.error('check_feature_imports: new violations present — fix them; --update-baseline only removes entries');
      [...newViolations, ...newEdges].forEach((id) => console.error(`  NEW ${id}`));
      return 1;
    }
    const today = new Date().toISOString().slice(0, 10);
    writeBaseline(opts.baseline, {
      ...baseline,
      violations: current.violations.filter((id) => baseViolations.has(id) || added.includes(id)),
      edges: edgeKeys.filter((e) => baseEdges.has(e) || added.includes(`R4|${e}`)),
      exceptions: [
        ...(baseline.exceptions || []).filter(
          (x) => currentSet.has(x.identity) || current.edges.has(x.identity.replace(/^R4\|/, '')),
        ),
        ...added.map((identity) => ({ identity, reason: opts.reason, accepted_on: today })),
      ],
    });
    console.log(
      `check_feature_imports: baseline updated (removed ${staleViolations.length + staleEdges.length}, ` +
        `accepted ${added.length})`,
    );
    return 0;
  }

  printSummary(current, edgeKeys);
  let failed = false;
  if (newViolations.length || newEdges.length) {
    failed = true;
    console.error('check_feature_imports: new cross-feature import violations (see docs/architecture/modularity.md):');
    [...newViolations, ...newEdges].forEach((id) => console.error(`  NEW ${id}`));
  }
  if (staleViolations.length || staleEdges.length) {
    failed = true;
    console.error(
      'check_feature_imports: baseline lists resolved entries — run `node scripts/check_feature_imports.js ' +
        '--update-baseline` and commit the smaller baseline:',
    );
    [...staleViolations, ...staleEdges.map((e) => `R4|${e}`)].forEach((id) => console.error(`  RESOLVED ${id}`));
  }
  if (!failed) console.log('check_feature_imports: OK (no new violations)');
  return failed ? 1 : 0;
}

if (require.main === module) {
  try {
    process.exit(main());
  } catch (err) {
    console.error(`check_feature_imports: ${err.message}`);
    process.exit(1);
  }
}

module.exports = { scan, classify, stronglyConnected, resolveSpec };
