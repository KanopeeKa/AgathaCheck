#!/usr/bin/env node
'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

describe('launch-cursor-agent module', () => {
  it('can be required without running main() (ISSUE_NUMBER not needed)', () => {
    const previousIssue = process.env.ISSUE_NUMBER;
    delete process.env.ISSUE_NUMBER;

    let mod;
    assert.doesNotThrow(() => {
      mod = require('./launch-cursor-agent');
    });

    assert.equal(typeof mod.launchAgent, 'function');
    if (previousIssue !== undefined) {
      process.env.ISSUE_NUMBER = previousIssue;
    }
  });
});

describe('launch-uat-coordinator module', () => {
  it('loads launchUatCoordinator when launch-cursor-agent is only required', () => {
    delete process.env.ISSUE_NUMBER;
    delete process.env.GITHUB_REPOSITORY;
    delete process.env.GITHUB_TOKEN;

    let mod;
    assert.doesNotThrow(() => {
      mod = require('./launch-uat-coordinator');
    });

    assert.equal(typeof mod.launchUatCoordinator, 'function');
    assert.equal(mod.COORDINATOR_MARKER, '<!-- uat-coordinator-run:');
  });
});
