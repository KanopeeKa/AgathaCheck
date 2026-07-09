'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { isAgentImplementationPr } = require('./agent-pr-safety-check');

test('isAgentImplementationPr matches standalone Refs line', () => {
  const body = '## Summary\n\nDocs change\n\nRefs #122\n';
  assert.equal(isAgentImplementationPr(body), true);
});

test('isAgentImplementationPr rejects prose mention of Fixes', () => {
  const body = 'The `Fixes #122` label closed the issue in prose.';
  assert.equal(isAgentImplementationPr(body), false);
});
