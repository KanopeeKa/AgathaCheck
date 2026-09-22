#!/usr/bin/env node
/**
 * Tests for scripts/lib/babysit_merge_preflight_lib.js
 */
const assert = require('node:assert/strict');
const {
  evaluateMergePreflight,
  findCompetingGreenPrs,
  findLeaseHolder,
  isBaseHot,
  isLeaseStale,
  isPrCiGreen,
  MERGE_LEASE_LABEL,
} = require('./lib/babysit_merge_preflight_lib.js');

const NOW = Date.parse('2026-09-22T12:00:00.000Z');

assert.equal(isPrCiGreen([{ state: 'SUCCESS' }, { state: 'SKIPPED' }]), true);
assert.equal(isPrCiGreen([{ state: 'SUCCESS' }, { state: 'FAILURE' }]), false);
assert.equal(isPrCiGreen([]), false);

assert.equal(
  isBaseHot('2026-09-22T11:55:00.000Z', NOW, 10),
  true,
  'base pushed 5m ago is hot',
);
assert.equal(
  isBaseHot('2026-09-22T11:40:00.000Z', NOW, 10),
  false,
  'base pushed 20m ago is not hot',
);

assert.equal(isLeaseStale('2026-09-22T11:00:00.000Z', NOW, 45), true);
assert.equal(isLeaseStale('2026-09-22T11:30:00.000Z', NOW, 45), false);

{
  const openPrs = [
    { number: 10, labels: [{ name: MERGE_LEASE_LABEL }], url: 'https://x/10' },
    { number: 11, labels: [] },
  ];
  const holder = findLeaseHolder(openPrs);
  assert.equal(holder.number, 10);
}

{
  const openPrs = [
    {
      number: 8,
      mergeable: 'MERGEABLE',
      statusCheckRollup: [{ state: 'SUCCESS' }],
    },
    {
      number: 12,
      mergeable: 'MERGEABLE',
      statusCheckRollup: [{ state: 'FAILURE' }],
    },
  ];
  const competing = findCompetingGreenPrs(openPrs, { prNumber: 9 });
  assert.deepEqual(competing.map((pr) => pr.number), [8]);
}

{
  const result = evaluateMergePreflight({
    prNumber: 20,
    behindBase: true,
  });
  assert.equal(result.allowed, false);
  assert.equal(result.exitCode, 1);
  assert.equal(result.reason, 'behind_base');
}

{
  const result = evaluateMergePreflight({
    prNumber: 20,
    leaseHolder: { number: 15, url: 'https://x/15' },
  });
  assert.equal(result.allowed, false);
  assert.equal(result.exitCode, 2);
  assert.equal(result.reason, 'merge_lease_held');
}

{
  const result = evaluateMergePreflight({
    prNumber: 20,
    leaseHolder: { number: 20 },
  });
  assert.equal(result.allowed, true);
}

{
  const result = evaluateMergePreflight({
    prNumber: 20,
    baseHot: true,
    competingGreenPrs: [{ number: 18, url: 'https://x/18' }],
  });
  assert.equal(result.allowed, false);
  assert.equal(result.reason, 'fifo_yield');
  assert.equal(result.yield_to.number, 18);
}

{
  const result = evaluateMergePreflight({
    prNumber: 20,
    baseHot: true,
    competingGreenPrs: [{ number: 25, url: 'https://x/25' }],
  });
  assert.equal(result.allowed, true);
  assert.equal(result.reason, 'clear');
}

{
  const result = evaluateMergePreflight({
    prNumber: 20,
    hasDoNotMerge: true,
  });
  assert.equal(result.exitCode, 3);
  assert.equal(result.reason, 'do_not_merge');
}

console.log('babysit_merge_preflight.test.js: ok');
