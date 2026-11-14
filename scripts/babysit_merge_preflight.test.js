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
  isLabelAlreadyAbsent,
  isLeaseStale,
  isPrCiGreen,
  leaseLabelApiArgs,
  MERGE_LEASE_LABEL,
  parsePrNumber,
  prRefCheckoutMismatch,
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
  assert.equal(result.action, 'rebase');
}

{
  const result = evaluateMergePreflight({
    prNumber: 2269,
    behindBase: true,
    headRefName: 'cursor/execute-plan-process-integration-prc1-3ca5',
    mergeable: 'MERGEABLE',
  });
  assert.equal(result.allowed, true);
  assert.equal(result.exitCode, 0);
  assert.equal(result.reason, 'clear');
}

{
  const result = evaluateMergePreflight({
    prNumber: 2269,
    behindBase: true,
    headRefName: 'cursor/execute-plan-process-integration-prc1-3ca5',
    mergeable: 'CONFLICTING',
  });
  assert.equal(result.allowed, false);
  assert.equal(result.exitCode, 4);
  assert.equal(result.reason, 'integration_conflict');
  assert.equal(result.action, 'resolve_on_release');
}

{
  const result = evaluateMergePreflight({
    prNumber: 2269,
    behindBase: true,
    headRefName: 'cursor/execute-plan-process-integration-prc1-3ca5',
    mergeable: 'UNKNOWN',
  });
  assert.equal(result.allowed, false);
  assert.equal(result.exitCode, 1);
  assert.equal(result.reason, 'integration_mergeability_unknown');
  assert.equal(result.action, 'recheck_mergeable');
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

assert.equal(parsePrNumber(2188), '2188');
assert.equal(parsePrNumber(' 2303 '), '2303');
assert.equal(
  parsePrNumber('https://github.com/AgathaTrack/AgathaTrack/pull/2303'),
  '2303',
);
assert.equal(
  parsePrNumber('https://github.com/AgathaTrack/AgathaTrack/pull/2303/files'),
  '2303',
);
assert.equal(parsePrNumber('cursor/some-head'), null);

const CHECKOUT = 'AgathaTrack/AgathaTrack';
assert.equal(
  prRefCheckoutMismatch('https://github.com/AgathaTrack/AgathaTrack/pull/2303', CHECKOUT),
  null,
);
assert.equal(
  prRefCheckoutMismatch(
    'https://github.com/AgathaTrack/AgathaTrack/pull/2303/files',
    CHECKOUT,
  ),
  null,
);
assert.equal(prRefCheckoutMismatch('2303', CHECKOUT), null);
assert.equal(prRefCheckoutMismatch('cursor/some-head', CHECKOUT), null);
assert.equal(
  prRefCheckoutMismatch('https://github.com/other/repo/pull/123', 'other/repo'),
  null,
);
assert.equal(
  prRefCheckoutMismatch('https://github.com/other/repo/pull/123', CHECKOUT),
  'PR URL targets other/repo#123; this checkout is AgathaTrack/AgathaTrack',
);
assert.equal(
  prRefCheckoutMismatch('https://github.com/other/repo/issues/2188', ''),
  'PR URL targets other/repo#2188; this checkout is (unknown)',
);

{
  const add = leaseLabelApiArgs(2188, 'add');
  assert.deepEqual(add, [
    'api',
    '--method',
    'POST',
    'repos/{owner}/{repo}/issues/2188/labels',
    '-f',
    'labels[]=merge-lease',
  ]);
  assert.equal(add.includes('edit'), false);
}

{
  const remove = leaseLabelApiArgs('2303', 'remove');
  assert.equal(remove[0], 'api');
  assert.equal(remove[2], 'DELETE');
  assert.equal(
    remove[3],
    'repos/{owner}/{repo}/issues/2303/labels/merge-lease',
  );
}

assert.equal(
  isLabelAlreadyAbsent('gh: Label does not exist (HTTP 404)\n', ''),
  true,
);
assert.equal(
  isLabelAlreadyAbsent('', '{"message":"Not Found","status":"404"}'),
  false,
);
assert.throws(() => leaseLabelApiArgs('https://github.com/x/y/pull/1', 'add'));
assert.throws(() => leaseLabelApiArgs(1, 'rename'));

console.log('babysit_merge_preflight.test.js: ok');
