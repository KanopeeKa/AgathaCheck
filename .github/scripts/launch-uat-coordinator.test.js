#!/usr/bin/env node
'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

const SCRIPT_DIR = __dirname;

function clearScriptModules() {
  for (const key of Object.keys(require.cache)) {
    if (key.startsWith(SCRIPT_DIR)) {
      delete require.cache[key];
    }
  }
}

function withEnv(overrides, fn) {
  const previous = {};
  for (const [name, value] of Object.entries(overrides)) {
    previous[name] = process.env[name];
    if (value === undefined) {
      delete process.env[name];
    } else {
      process.env[name] = value;
    }
  }

  try {
    return fn();
  } finally {
    for (const [name, value] of Object.entries(previous)) {
      if (value === undefined) {
        delete process.env[name];
      } else {
        process.env[name] = value;
      }
    }
  }
}

describe('launch-cursor-agent module', () => {
  it('can be required without running main() (ISSUE_NUMBER not needed)', () => {
    clearScriptModules();
    withEnv({ ISSUE_NUMBER: undefined }, () => {
      let mod;
      assert.doesNotThrow(() => {
        mod = require('./launch-cursor-agent');
      });
      assert.equal(typeof mod.launchAgent, 'function');
    });
  });
});

describe('launch-uat-coordinator module', () => {
  it('loads launchUatCoordinator when launch-cursor-agent is only required', () => {
    clearScriptModules();
    withEnv({
      ISSUE_NUMBER: undefined,
      GITHUB_REPOSITORY: undefined,
      GITHUB_TOKEN: undefined,
    }, () => {
      let mod;
      assert.doesNotThrow(() => {
        mod = require('./launch-uat-coordinator');
      });
      assert.equal(typeof mod.launchUatCoordinator, 'function');
      assert.equal(mod.COORDINATOR_MARKER, '<!-- uat-coordinator-run:');
    });
  });
});
