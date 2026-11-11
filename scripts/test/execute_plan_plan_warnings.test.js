'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { warnCrossPlanWaitPhrases, stripFencedBlocks } = require('../lib/execute_plan_plan_warnings');

test('stripFencedBlocks removes json scope blocks', () => {
  const md = ['# Title', '```json', 'wait for evil', '{ "x": 1 }', '```', 'after'];
  assert.equal(stripFencedBlocks(md.join('\n')).includes('wait for evil'), false);
  assert.ok(stripFencedBlocks(md.join('\n')).includes('after'));
});

test('warnCrossPlanWaitPhrases logs cross-plan coordination phrases', () => {
  const lines = [];
  const md = [
    '# Roadmap',
    'On STOP use human_pause until entry gate clears.',
    'Also wait for `people-client-integration-7f3b` before phase 3.',
    '```json',
    '{ "allowed_paths": [] }',
    '```',
  ].join('\n');
  warnCrossPlanWaitPhrases(md, { log: (m) => lines.push(m) });
  assert.ok(lines.some((l) => /human-pause/.test(l)));
  assert.ok(lines.some((l) => /entry-gate/.test(l)));
  assert.ok(lines.some((l) => /wait-for-plan-id/.test(l)));
});

test('warnCrossPlanWaitPhrases ignores fenced wait-for inside json', () => {
  const lines = [];
  const md = ['# OK', '```json', '{ "note": "wait for format" }', '```'].join('\n');
  warnCrossPlanWaitPhrases(md, { log: (m) => lines.push(m) });
  assert.equal(lines.length, 0);
});
