'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createGitHubClient } = require('../lib/execute_plan_github');
const { createFakeFetch } = require('./helpers/execute_plan_fake_fetch');
const { checkUatTagOnMain, commitIsOnMain, stripRefPrefix } = require('../lib/main_ancestry');

const R = '/repos/o/r';
const SHA = 'c'.repeat(40);
const TAG = 'uat-261020-1943';

function client(routes) {
  return createGitHubClient({ repo: 'o/r', token: 't', fetchImpl: createFakeFetch(routes), sleep: async () => {} });
}

const tagRoute = { [`GET ${R}/commits/refs/tags/${TAG}`]: { body: { sha: SHA } } };
const cmp = (status) => ({ [`GET ${R}/compare/${SHA}...main`]: status });

test('stripRefPrefix', () => {
  assert.equal(stripRefPrefix(`refs/tags/${TAG}`), TAG);
  assert.equal(stripRefPrefix(' refs/heads/main '), 'main');
});

test('commitIsOnMain: ahead and identical are on main; diverged, behind and unknown are not', async () => {
  for (const [status, expected] of [['ahead', true], ['identical', true], ['diverged', false], ['behind', false]]) {
    assert.equal(await commitIsOnMain(client(cmp({ body: { status } })), SHA), expected, status);
  }
  assert.equal(await commitIsOnMain(client(cmp({ status: 404, body: {} })), SHA), false);
  await assert.rejects(commitIsOnMain(client(cmp({ status: 401, body: {} })), SHA), /401/);
});

test('checkUatTagOnMain happy path accepts refs/tags/ prefix', async () => {
  const r = await checkUatTagOnMain(client({ ...tagRoute, ...cmp({ body: { status: 'ahead' } }) }), `refs/tags/${TAG}`);
  assert.deepEqual(r, { ok: true, tag: TAG, commitSha: SHA });
});

test('checkUatTagOnMain refuses a tag whose commit is not on main', async () => {
  const r = await checkUatTagOnMain(client({ ...tagRoute, ...cmp({ body: { status: 'diverged' } }) }), TAG);
  assert.equal(r.code, 'commit_not_on_main');
  assert.equal(r.commitSha, SHA);
});

test('checkUatTagOnMain refuses non-UAT refs and missing tags', async () => {
  const gh = client({ [`GET ${R}/commits/refs/tags/${TAG}`]: { status: 404, body: {} } });
  assert.equal((await checkUatTagOnMain(gh, 'main')).code, 'not_a_uat_tag');
  assert.equal((await checkUatTagOnMain(gh, 'uat-1-2;rm')).code, 'not_a_uat_tag');
  assert.equal((await checkUatTagOnMain(gh, TAG)).code, 'tag_not_found');
});
