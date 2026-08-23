#!/usr/bin/env node
/**
 * Tests for e2e_debug_resolve.mjs
 */
import assert from 'node:assert/strict';
import { computeTargetShards } from './e2e_debug_resolve.mjs';

{
  const target = computeTargetShards([3], [{ index: 12, risk: 'high' }], ['docs/readme.md']);
  assert.deepEqual(target, [3, 12]);
}

{
  const target = computeTargetShards([], [{ index: 5, risk: 'medium' }, { index: 2, risk: 'low' }], [
    'e2e/playwright/support/flutter.ts',
  ]);
  assert.deepEqual(target, [2, 5]);
}

{
  const target = computeTargetShards([], [{ index: 5, risk: 'low' }], ['docs/readme.md']);
  assert.deepEqual(target, []);
}

{
  const target = computeTargetShards([10, 3], [{ index: 3, risk: 'high' }], []);
  assert.deepEqual(target, [3, 10]);
}

console.log('e2e_debug_resolve tests passed');
