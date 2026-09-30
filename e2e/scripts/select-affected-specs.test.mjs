import assert from 'node:assert/strict';
import test from 'node:test';

import { selectSpecs } from './select-affected-specs.mjs';
import { activeSpecs, balanceSpecs, SHARDS } from './shard-files.mjs';
import { AREAS, mappedSpecs } from './spec-domains.mjs';

const seconds = { 'a.spec.ts': 400, 'b.spec.ts': 300, 'c.spec.ts': 200, 'd.spec.ts': 100 };
const ctx = (over = {}) => ({
  active: Object.keys(seconds),
  imports: new Map([
    ['a.spec.ts', new Set(['shared.page.ts'])],
    ['b.spec.ts', new Set(['shared.page.ts', 'b.page.ts'])],
    ['c.spec.ts', new Set()],
    ['d.spec.ts', new Set()],
  ]),
  secondsOf: (s) => seconds[s] ?? 90,
  budgetSec: 720,
  maxLegs: 3,
  ...over,
});

test('direct spec and page-object changes select their specs', () => {
  const out = selectSpecs(['e2e/playwright/tests/d.spec.ts', 'e2e/playwright/pages/b.page.ts'], ctx());
  assert.deepEqual(out.selected, ['b.spec.ts', 'd.spec.ts']);
  assert.equal(out.estimated_sec, 400);
  assert.equal(out.broad, false);
});

test('budget defers lower-priority specs to Pre-UAT', () => {
  const out = selectSpecs(['e2e/playwright/pages/shared.page.ts', 'e2e/playwright/tests/c.spec.ts'], ctx({ budgetSec: 650 }));
  // tier 0 (c) first, then tier 1 longest-first: a (400) fits (600), b (300) does not
  assert.deepEqual(out.selected, ['a.spec.ts', 'c.spec.ts']);
  assert.deepEqual(out.deferred, ['b.spec.ts']);
});

test('a directly changed spec always runs even when it alone exceeds the budget', () => {
  const out = selectSpecs(['e2e/playwright/tests/a.spec.ts'], ctx({ budgetSec: 100 }));
  assert.deepEqual(out.selected, ['a.spec.ts']);
});

test('frozen or unknown specs are never selected', () => {
  const out = selectSpecs(['e2e/playwright/tests/organisation.edit.spec.ts', 'docs/x.md'], ctx());
  assert.deepEqual(out.selected, []);
  assert.deepEqual(out.legs, []);
});

test('broad changes keep direct specs and defer area matches', () => {
  const real = activeSpecs();
  const out = selectSpecs(
    ['e2e/playwright/support/api.ts', 'e2e/playwright/tests/veterinarian.spec.ts', 'flutter_app/lib/features/experience/x.dart'],
    { active: real, imports: new Map(), secondsOf: () => 100 },
  );
  assert.equal(out.broad, true);
  assert.deepEqual(out.selected, ['veterinarian.spec.ts']);
  assert.ok(out.deferred.includes('guardian.navigation.spec.ts'));
});

test('legs are capped and balanced', () => {
  const out = selectSpecs(
    ['e2e/playwright/tests/a.spec.ts', 'e2e/playwright/tests/b.spec.ts', 'e2e/playwright/tests/c.spec.ts', 'e2e/playwright/tests/d.spec.ts'],
    ctx({ budgetSec: 2000, maxLegs: 2 }),
  );
  assert.equal(out.legs.length, 2);
  assert.equal(out.legs.flat().length, 4);
});

test('balanceSpecs is deterministic LPT', () => {
  const { shards, loads } = balanceSpecs(['d.spec.ts', 'a.spec.ts', 'c.spec.ts', 'b.spec.ts'], 2, (s) => seconds[s]);
  assert.deepEqual(shards, [['a.spec.ts', 'd.spec.ts'], ['b.spec.ts', 'c.spec.ts']]);
  assert.deepEqual(loads, [500, 500]);
});

test('every active spec is mapped to an area, and every mapped spec is active', () => {
  const active = new Set(activeSpecs());
  const mapped = mappedSpecs();
  assert.deepEqual([...active].filter((s) => !mapped.has(s)), [], 'add unmapped specs to spec-domains.mjs AREAS');
  assert.deepEqual([...mapped].filter((s) => !active.has(s)), [], 'spec-domains.mjs names a missing/frozen spec');
  assert.ok(Object.keys(AREAS).length > 0);
});

test('Pre-UAT manifest covers every active spec exactly once', () => {
  const flat = SHARDS.flat().map((p) => p.replace('playwright/tests/', ''));
  assert.equal(new Set(flat).size, flat.length);
  assert.deepEqual([...flat].sort(), activeSpecs());
});
