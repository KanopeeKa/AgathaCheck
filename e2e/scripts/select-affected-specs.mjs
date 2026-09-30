#!/usr/bin/env node
/**
 * Pick the Playwright specs a PR should run before merge, within a time budget.
 *
 * Tiers (highest first): 0 = spec file changed; 1 = a page object it imports changed;
 * 2 = product area changed (spec-domains.mjs AREAS). Frozen specs are never selected.
 * Broad changes (core, l10n, support/, config…) select only tiers 0–1 — the @smoke-ci
 * canary and Pre-UAT cover the rest. Specs are added tier by tier, longest first within
 * a tier, while the estimated total stays within the budget; the rest is reported as
 * deferred to Pre-UAT. Selected specs are LPT-balanced into at most `maxLegs` legs.
 *
 * Usage:
 *   git diff --name-only BASE HEAD | node e2e/scripts/select-affected-specs.mjs [--budget-sec 720] [--max-legs 3]
 *   node e2e/scripts/select-affected-specs.mjs --paths-file changed.txt
 * Prints JSON: { legs: string[][], selected, deferred, broad, estimated_sec, reasons }
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { AREAS, areasForPath, isBroadPath } from './spec-domains.mjs';
import { activeSpecs, balanceSpecs, specSeconds } from './shard-files.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const TESTS_DIR = path.join(here, '..', 'playwright', 'tests');

/** spec basename → page-object basenames it imports (e.g. care-suggestion.page.ts). */
export function pageImports(testsDir = TESTS_DIR, specs = activeSpecs(testsDir)) {
  const map = new Map();
  for (const spec of specs) {
    const text = fs.readFileSync(path.join(testsDir, spec), 'utf8');
    const pages = [...text.matchAll(/from\s+['"]\.\.\/pages\/([\w.-]+?)(?:\.ts)?['"]/g)].map((m) => `${m[1]}.ts`);
    map.set(spec, new Set(pages));
  }
  return map;
}

/**
 * @param {string[]} changedPaths repo-relative
 * @param {{ active: string[], imports: Map<string, Set<string>>, secondsOf: (s: string) => number,
 *           budgetSec?: number, maxLegs?: number }} ctx
 */
export function selectSpecs(changedPaths, ctx) {
  const { active, imports, secondsOf, budgetSec = 720, maxLegs = 3 } = ctx;
  const activeSet = new Set(active);
  const tier = new Map(); // spec → best (lowest) tier
  const reasons = new Map();
  const note = (spec, t, why) => {
    if (!activeSet.has(spec)) return;
    if (!tier.has(spec) || t < tier.get(spec)) tier.set(spec, t);
    if (!reasons.has(spec)) reasons.set(spec, new Set());
    reasons.get(spec).add(why);
  };
  let broad = false;

  for (const p of changedPaths) {
    const specMatch = p.match(/^e2e\/playwright\/tests\/([^/]+\.spec\.ts)$/);
    if (specMatch) note(specMatch[1], 0, `spec changed: ${p}`);
    const pageMatch = p.match(/^e2e\/playwright\/pages\/([^/]+\.ts)$/);
    if (pageMatch) {
      for (const [spec, pages] of imports) if (pages.has(pageMatch[1])) note(spec, 1, `page object changed: ${p}`);
    }
    if (isBroadPath(p)) broad = true;
    for (const area of areasForPath(p)) for (const spec of AREAS[area].specs) note(spec, 2, `${area} changed: ${p}`);
  }

  const candidates = [...tier.keys()]
    .filter((spec) => !broad || tier.get(spec) < 2)
    .sort((a, b) => tier.get(a) - tier.get(b) || secondsOf(b) - secondsOf(a) || a.localeCompare(b));
  const selected = [];
  const deferred = broad ? [...tier.keys()].filter((spec) => tier.get(spec) === 2).sort() : [];
  let total = 0;
  for (const spec of candidates) {
    if (total + secondsOf(spec) <= budgetSec || selected.length === 0 && tier.get(spec) === 0) {
      selected.push(spec);
      total += secondsOf(spec);
    } else {
      deferred.push(spec);
    }
  }
  const legCount = Math.min(maxLegs, selected.length, Math.max(1, Math.ceil(total / 300)));
  const legs = selected.length ? balanceSpecs(selected, legCount, secondsOf).shards.filter((l) => l.length) : [];
  return {
    legs: legs.map((leg) => leg.map((spec) => `playwright/tests/${spec}`)),
    selected: [...selected].sort(),
    deferred: [...new Set(deferred)].sort(),
    broad,
    estimated_sec: total,
    reasons: Object.fromEntries([...reasons].map(([spec, why]) => [spec, [...why]])),
  };
}

function readPaths(argv) {
  const fileIdx = argv.indexOf('--paths-file');
  const text = fileIdx !== -1 ? fs.readFileSync(argv[fileIdx + 1], 'utf8') : fs.readFileSync(0, 'utf8');
  return text.split('\n').map((l) => l.trim()).filter(Boolean);
}

function numArg(argv, name, fallback) {
  const idx = argv.indexOf(name);
  const value = idx !== -1 ? Number(argv[idx + 1]) : NaN;
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1])) {
  const argv = process.argv.slice(2);
  const active = activeSpecs();
  const result = selectSpecs(readPaths(argv), {
    active,
    imports: pageImports(TESTS_DIR, active),
    secondsOf: (spec) => specSeconds(spec),
    budgetSec: numArg(argv, '--budget-sec', 720),
    maxLegs: numArg(argv, '--max-legs', 3),
  });
  console.log(JSON.stringify(result));
}
