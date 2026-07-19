import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizeStoredToken } from './normalize-stored-token.ts';

test('unwraps JSON-encoded JWT string from shared_preferences_web', () => {
  assert.equal(
    normalizeStoredToken('"abc.def.ghi"'),
    'abc.def.ghi',
  );
});

test('leaves plain JWT unchanged', () => {
  const token = 'abc.def.ghi';
  assert.equal(normalizeStoredToken(token), token);
});

test('trims surrounding whitespace', () => {
  assert.equal(normalizeStoredToken('  abc.def.ghi  '), 'abc.def.ghi');
});

test('throws on empty or missing values', () => {
  assert.throws(() => normalizeStoredToken(''), /missing from localStorage/);
  assert.throws(() => normalizeStoredToken(null), /missing from localStorage/);
  assert.throws(() => normalizeStoredToken(undefined), /missing from localStorage/);
  assert.throws(() => normalizeStoredToken('   '), /missing from localStorage/);
});

test('throws when value is not JWT-shaped after normalization', () => {
  assert.throws(() => normalizeStoredToken('"not-a-jwt"'), /JWT-shape validation/);
  assert.throws(() => normalizeStoredToken('only-two.parts'), /JWT-shape validation/);
});
