'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { botLaunchEnvVars } = require('../../.github/scripts/launch-cursor-agent');

test('botLaunchEnvVars returns bot tokens and blanked owner keys when EXECUTE_PLAN_BOT_TOKEN is set', () => {
  const env = { EXECUTE_PLAN_BOT_TOKEN: 'bot-secret' };
  assert.deepEqual(botLaunchEnvVars(env), {
    GH_TOKEN: 'bot-secret',
    EXECUTE_PLAN_TOKEN: 'bot-secret',
    OWNER_GH_TOKEN: '',
    BOT_GH_TOKEN: '',
  });
});

test('botLaunchEnvVars returns only blanked keys when token missing or blank', () => {
  assert.deepEqual(botLaunchEnvVars({}), { OWNER_GH_TOKEN: '', BOT_GH_TOKEN: '' });
  assert.deepEqual(botLaunchEnvVars({ EXECUTE_PLAN_BOT_TOKEN: '  ' }), {
    OWNER_GH_TOKEN: '',
    BOT_GH_TOKEN: '',
  });
});
