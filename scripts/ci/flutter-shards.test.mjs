import assert from 'node:assert/strict';
import test from 'node:test';

import {
  buildOwnership,
  classifyTestFile,
  listTestFiles,
  loadFrozenTestRoots,
  loadManifest,
} from './flutter-shards.mjs';

const manifest = {
  excludedRoots: ['test/features/pet_profile/presentation/integration'],
  shards: [
    { id: 'pet-profile', roots: ['test/features/pet_profile'] },
    { id: 'core', roots: ['test/core', 'test/features/people'] },
  ],
};
const frozenRoots = ['test/features/organization'];

test('classifies owned, frozen, excluded and unowned files', () => {
  assert.deepEqual(classifyTestFile('test/core/utils/calendar_date_test.dart', manifest, frozenRoots), {
    kind: 'shard',
    shard: 'core',
  });
  assert.deepEqual(
    classifyTestFile('test/features/organization/x_test.dart', manifest, frozenRoots),
    { kind: 'frozen' },
  );
  assert.deepEqual(
    classifyTestFile(
      'test/features/pet_profile/presentation/integration/pet_profile_flow_test.dart',
      manifest,
      frozenRoots,
    ),
    { kind: 'excluded' },
  );
  assert.deepEqual(classifyTestFile('test/features/vet/vet_test.dart', manifest, frozenRoots), {
    kind: 'unowned',
  });
});

test('root matching is path-segment aware (no prefix bleed)', () => {
  // test/core must not own test/core_extras/...
  assert.equal(
    classifyTestFile('test/core_extras/a_test.dart', manifest, frozenRoots).kind,
    'unowned',
  );
});

test('overlapping roots are reported as multi-owned', () => {
  const overlapping = {
    excludedRoots: [],
    shards: [
      { id: 'a', roots: ['test/features/health_tracking'] },
      { id: 'b', roots: ['test/features/health_tracking/domain'] },
    ],
  };
  const result = classifyTestFile('test/features/health_tracking/domain/x_test.dart', overlapping, []);
  assert.deepEqual(result, { kind: 'multi', shards: ['a', 'b'] });
});

test('buildOwnership groups files per shard and collects gaps', () => {
  const files = [
    'test/core/a_test.dart',
    'test/features/people/b_test.dart',
    'test/features/pet_profile/c_test.dart',
    'test/features/organization/d_test.dart',
    'test/features/vet/e_test.dart',
  ];
  const { byShard, unowned, multi, frozen } = buildOwnership({ manifest, frozenRoots, files });
  assert.deepEqual(byShard.get('core'), ['test/core/a_test.dart', 'test/features/people/b_test.dart']);
  assert.deepEqual(byShard.get('pet-profile'), ['test/features/pet_profile/c_test.dart']);
  assert.deepEqual(unowned, ['test/features/vet/e_test.dart']);
  assert.deepEqual(multi, []);
  assert.equal(frozen, 1);
});

test('repository manifest owns every active Flutter test exactly once', () => {
  const repoManifest = loadManifest();
  const { unowned, multi, byShard } = buildOwnership({
    manifest: repoManifest,
    frozenRoots: loadFrozenTestRoots(),
    files: listTestFiles(),
  });
  assert.deepEqual(unowned, [], `unowned test files: ${unowned.join(', ')}`);
  assert.deepEqual(multi, []);
  for (const [id, files] of byShard) assert.ok(files.length > 0, `shard ${id} is empty`);
});
