#!/usr/bin/env node
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { parseFlags, readBody } = require('./lib/github_issue_workflow_lib');

test('parseFlags reads boolean and value flags', () => {
  assert.deepEqual(parseFlags(['--issue', '12', '--body', 'hi', '--write']), {
    issue: '12',
    body: 'hi',
    write: true,
  });
});

test('readBody prefers --body over --body-file', () => {
  const body = readBody({ body: 'inline', 'body-file': '/tmp/ignored' });
  assert.equal(body, 'inline');
});

test('readBody reads --body-file', () => {
  const file = path.join(os.tmpdir(), `issue-body-${process.pid}.txt`);
  fs.writeFileSync(file, 'from file\n');
  try {
    assert.equal(readBody({ 'body-file': file }), 'from file\n');
  } finally {
    fs.unlinkSync(file);
  }
});
