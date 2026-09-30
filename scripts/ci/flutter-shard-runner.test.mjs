import assert from 'node:assert/strict';
import test from 'node:test';

import { chunk, parseReport, planRun, toRelative, unprovenFiles } from './flutter-shard-runner.mjs';
import { formatLcov, parseLcov } from './lcov-merge.mjs';

const ev = (o) => JSON.stringify(o);
const suite = (id, file) => ev({ type: 'suite', suite: { id, path: `/w/repo/flutter_app/${file}` } });
const root = (suiteID, testCount) => ev({ type: 'group', group: { id: 100 + suiteID, suiteID, parentID: null, testCount } });
const start = (id, suiteID) => ev({ type: 'testStart', test: { id, suiteID, name: `t${id}` } });
const done = (testID, result = 'success', hidden = false) => ev({ type: 'testDone', testID, result, hidden, skipped: false });

test('toRelative strips everything up to flutter_app/', () => {
  assert.equal(toRelative('/home/x/AgathaCheck/flutter_app/test/a_test.dart'), 'test/a_test.dart');
});

test('parseReport marks passed, failed and incomplete suites', () => {
  const text = [
    suite(0, 'test/pass_test.dart'), root(0, 2), start(1, 0), done(1, 'success', true), start(2, 0), done(2), start(3, 0), done(3),
    suite(1, 'test/fail_test.dart'), root(1, 1), start(4, 1), done(4, 'failure'),
    suite(2, 'test/crash_test.dart'), root(2, 3), start(5, 2), done(5),
    suite(3, 'test/load_error_test.dart'), start(6, 3), ev({ type: 'error', testID: 6, error: 'segfault' }), done(6, 'error', true),
  ].join('\n');
  const report = parseReport(text);
  const files = ['test/pass_test.dart', 'test/fail_test.dart', 'test/crash_test.dart', 'test/load_error_test.dart', 'test/never_test.dart'];
  assert.deepEqual(unprovenFiles(files, report), [
    'test/fail_test.dart',
    'test/crash_test.dart',
    'test/load_error_test.dart',
    'test/never_test.dart',
  ]);
});

test('chunk splits evenly with a remainder', () => {
  assert.deepEqual(chunk([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]]);
});

test('lcov merge sums hits and recomputes LF/LH', () => {
  const merged = new Map();
  parseLcov('SF:lib/a.dart\nDA:1,0\nDA:2,1\nLF:2\nLH:1\nend_of_record\n', merged);
  parseLcov('SF:lib/a.dart\nDA:1,3\nDA:3,0\nend_of_record\nSF:lib/b.dart\nDA:5,2\nend_of_record\n', merged);
  assert.equal(
    formatLcov(merged),
    'SF:lib/a.dart\nDA:1,3\nDA:2,1\nDA:3,0\nLF:3\nLH:2\nend_of_record\nSF:lib/b.dart\nDA:5,2\nLF:1\nLH:1\nend_of_record\n',
  );
});

test('planRun runs per-file roots alone and batches the rest', () => {
  const files = ['test/core/a_test.dart', 'test/features/auth/b_test.dart', 'test/features/sharing/c_test.dart', 'test/features/auth/d_test.dart'];
  assert.deepEqual(planRun(files, ['test/features/auth'], 10), {
    perFile: ['test/features/auth/b_test.dart', 'test/features/auth/d_test.dart'],
    batches: [['test/core/a_test.dart', 'test/features/sharing/c_test.dart']],
  });
  assert.deepEqual(planRun(['test/core/a_test.dart'], [], 10), { perFile: [], batches: [['test/core/a_test.dart']] });
});
