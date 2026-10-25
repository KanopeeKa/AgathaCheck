'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { botLaunchEnvVars } = require('../../.github/scripts/launch-cursor-agent');

test('botLaunchEnvVars returns GH_TOKEN and EXECUTE_PLAN_TOKEN when EXECUTE_PLAN_BOT_TOKEN is set', () => {
  const env = { EXECUTE_PLAN_BOT_TOKEN: 'bot-secret' };
  assert.deepEqual(botLaunchEnvVars(env), {
    GH_TOKEN: 'bot-secret',
    EXECUTE_PLAN_TOKEN: 'bot-secret',
  });
});

test('botLaunchEnvVars returns undefined when token missing', () => {
  assert.equal(botLaunchEnvVars({}), undefined);
  assert.equal(botLaunchEnvVars({ EXECUTE_PLAN_BOT_TOKEN: '  ' }), undefined);
});
