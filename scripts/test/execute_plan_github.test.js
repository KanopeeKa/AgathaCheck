'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  createGitHubClient,
  MissingToken,
  RateLimited,
  PullFilesOverflow,
  GitHubError,
} = require('../lib/execute_plan_github');
const { createFakeFetch } = require('./helpers/execute_plan_fake_fetch');

const R = '/repos/acme/app';
const TOKEN_ENV = ['EXECUTE_PLAN_TOKEN', 'GH_TOKEN', 'GITHUB_TOKEN'];

function client(routes, extra = {}) {
  const fake = createFakeFetch(routes);
  const sleeps = [];
  const gh = createGitHubClient({
    repo: 'acme/app',
    token: 'tkn',
    fetchImpl: fake,
    sleep: async (ms) => {
      sleeps.push(ms);
    },
    ...extra,
  });
  return { gh, fake, sleeps };
}

async function withEnv(values, fn) {
  const saved = {};
  for (const key of TOKEN_ENV) {
    saved[key] = process.env[key];
    if (values[key] === undefined) delete process.env[key];
    else process.env[key] = values[key];
  }
  try {
    await fn();
  } finally {
    for (const key of TOKEN_ENV) {
      if (saved[key] === undefined) delete process.env[key];
      else process.env[key] = saved[key];
    }
  }
}

test('pagination follows Link', async () => {
  const next = `https://api.github.com${R}/issues/5/comments?per_page=100&page=2`;
  const { gh, fake } = client({
    [`GET ${R}/issues/5/comments?per_page=100`]: {
      headers: { link: `<${next}>; rel="next", <${next}>; rel="last"` },
      body: [{ id: 1 }, { id: 2 }],
    },
    [`GET ${R}/issues/5/comments?page=2&per_page=100`]: { body: [{ id: 3 }] },
  });
  const comments = await gh.listIssueComments(5);
  assert.deepEqual(comments.map((c) => c.id), [1, 2, 3]);
  assert.equal(fake.calls.length, 2);

  const limited = await gh.listIssueComments(5, { pages: 1 });
  assert.deepEqual(limited.map((c) => c.id), [1, 2]);

  const foreign = client({
    [`GET ${R}/tags?per_page=100`]: { headers: { link: '<https://evil.example/tags?page=2>; rel="next"' }, body: [] },
  });
  await assert.rejects(foreign.gh.listTags(), /another origin/);
  assert.equal(foreign.fake.calls.length, 1);
});

test('listPullFiles overflow throws PullFilesOverflow', async () => {
  const page = (p) => ({
    headers: p < 30 ? { link: `<https://api.github.com${R}/pulls/9/files?per_page=100&page=${p + 1}>; rel="next"` } : {},
    body: Array.from({ length: 100 }, (_, i) => ({ filename: `f${p}-${i}.js` })),
  });
  const routes = { [`GET ${R}/pulls/9/files?per_page=100`]: page(1), [`GET ${R}/pulls/9`]: { body: { changed_files: 3412 } } };
  for (let p = 2; p <= 30; p += 1) routes[`GET ${R}/pulls/9/files?page=${p}&per_page=100`] = page(p);
  const { gh } = client(routes);
  await assert.rejects(gh.listPullFiles(9), PullFilesOverflow);

  const small = client({ [`GET ${R}/pulls/3/files?per_page=100`]: { body: [{ filename: 'a.js' }] } });
  assert.deepEqual(await small.gh.listPullFiles(3), [{ filename: 'a.js' }]);
});

test('retry on 502 then success', async () => {
  const { gh, sleeps } = client({
    [`GET ${R}/issues/1`]: [{ status: 502, body: 'bad gateway' }, { status: 504 }, { body: { number: 1 } }],
  });
  assert.deepEqual(await gh.getIssue(1), { number: 1 });
  assert.deepEqual(sleeps, [2000, 4000]);
});

test('retries are bounded (3) and then throw GitHubError', async () => {
  const { gh, fake, sleeps } = client({ [`GET ${R}/issues/1`]: { status: 503, body: { message: 'down' } } });
  await assert.rejects(gh.getIssue(1), (err) => err instanceof GitHubError && err.status === 503);
  assert.equal(fake.calls.length, 4);
  assert.deepEqual(sleeps, [2000, 4000, 8000]);
});

test('request timeout surfaces as an error', async () => {
  const calls = [];
  const sleeps = [];
  const gh = createGitHubClient({
    repo: 'acme/app',
    token: 'tkn',
    sleep: async (ms) => {
      sleeps.push(ms);
    },
    fetchImpl: async (url, init) => {
      calls.push(init);
      if (init.signal) throw new DOMException('The operation was aborted due to timeout', 'TimeoutError');
      return new Response('{}', { status: 200 });
    },
  });
  await assert.rejects(gh.getIssue(1), { name: 'TimeoutError' });
  assert.ok(calls[0].signal instanceof AbortSignal);
  assert.equal(calls.length, 1);
  assert.deepEqual(sleeps, []);
});

test('secondary rate limit retried then succeeds', async () => {
  const { gh, sleeps } = client({
    [`POST ${R}/issues/2/comments`]: [
      { status: 403, body: { message: 'You have exceeded a secondary rate limit.' } },
      { status: 201, body: { id: 77 } },
    ],
  });
  assert.deepEqual(await gh.createComment(2, 'hi'), { id: 77 });
  assert.deepEqual(sleeps, [2000]);
});

test('rate limit remaining 0 throws RateLimited', async () => {
  const { gh, fake } = client({
    [`GET ${R}/issues/1`]: {
      status: 403,
      headers: { 'x-ratelimit-remaining': '0', 'x-ratelimit-reset': '1792000000' },
      body: { message: 'API rate limit exceeded' },
    },
  });
  await assert.rejects(gh.getIssue(1), (err) => {
    assert.ok(err instanceof RateLimited);
    assert.equal(err.resetAt, new Date(1792000000 * 1000).toISOString());
    return true;
  });
  assert.equal(fake.calls.length, 1);
});

test('token resolution order', async () => {
  const routes = { [`GET ${R}/issues/1`]: { body: {} } };
  const authOf = async (opts) => {
    const fake = createFakeFetch(routes);
    await createGitHubClient({ repo: 'acme/app', fetchImpl: fake, ...opts }).getIssue(1);
    return fake.calls[0].headers.authorization;
  };
  await withEnv({ EXECUTE_PLAN_TOKEN: 'ep', GH_TOKEN: 'gh', GITHUB_TOKEN: 'ghs' }, async () => {
    assert.equal(await authOf({ token: 'explicit' }), 'Bearer explicit');
    assert.equal(await authOf({}), 'Bearer ep');
  });
  await withEnv({ GH_TOKEN: 'gh', GITHUB_TOKEN: 'ghs' }, async () => {
    assert.equal(await authOf({}), 'Bearer gh');
  });
  await withEnv({ GITHUB_TOKEN: 'ghs' }, async () => {
    assert.equal(await authOf({}), 'Bearer ghs');
  });
});

test('missing token throws on first call', async () => {
  await withEnv({}, async () => {
    const fake = createFakeFetch({});
    const gh = createGitHubClient({ repo: 'acme/app', fetchImpl: fake });
    await assert.rejects(gh.getIssue(1), MissingToken);
    assert.equal(fake.calls.length, 0);
  });
});

test('request headers and error messages never carry the token', async () => {
  const { gh, fake } = client({ [`GET ${R}/pulls/4`]: { status: 500, body: { message: 'boom' } } });
  await assert.rejects(gh.getPull(4), (err) => {
    assert.ok(err instanceof GitHubError);
    assert.equal(err.status, 500);
    assert.match(err.message, /^GET \/repos\/acme\/app\/pulls\/4 failed with 500/);
    assert.doesNotMatch(err.message, /tkn/);
    return true;
  });
  const h = fake.calls[0].headers;
  assert.equal(h.accept, 'application/vnd.github+json');
  assert.equal(h['x-github-api-version'], '2022-11-28');
  assert.equal(h['user-agent'], 'execute-plan/2');
});

test('getBranch 404 returns null', async () => {
  const { gh } = client({
    [`GET ${R}/branches/cursor%2Fx-p1`]: { status: 404, body: { message: 'Branch not found' } },
    [`GET ${R}/issues/404`]: { status: 404, body: { message: 'Not Found' } },
    [`DELETE ${R}/issues/1/labels/busy`]: { status: 404, body: { message: 'Label does not exist' } },
  });
  assert.equal(await gh.getBranch('cursor/x-p1'), null);
  await gh.removeLabel(1, 'busy');
  await assert.rejects(gh.getIssue(404), (err) => err instanceof GitHubError && err.status === 404);
});

test('getFileAtRef decodes base64 content', async () => {
  const text = '# Plan — é\n';
  const b64 = Buffer.from(text).toString('base64').replace(/(.{8})/g, '$1\n');
  const { gh } = client({
    [`GET ${R}/contents/.agents/plans/p.md?ref=abc123`]: {
      body: { type: 'file', encoding: 'base64', content: b64, sha: 'blob1' },
    },
    [`GET ${R}/contents/missing.md?ref=main`]: { status: 404, body: { message: 'Not Found' } },
  });
  assert.deepEqual(await gh.getFileAtRef('.agents/plans/p.md', 'abc123'), { content: text, sha: 'blob1' });
  assert.equal(await gh.getFileAtRef('missing.md', 'main'), null);
});

test('compare maps fields', async () => {
  const { gh } = client({
    [`GET ${R}/compare/aaa...bbb`]: {
      body: {
        status: 'ahead',
        ahead_by: 2,
        behind_by: 0,
        total_commits: 2,
        files: [{ filename: 'a.js', status: 'modified', patch: '@@' }],
      },
    },
  });
  assert.deepEqual(await gh.compare('aaa', 'bbb'), {
    status: 'ahead',
    ahead_by: 2,
    behind_by: 0,
    files: [{ filename: 'a.js', status: 'modified' }],
  });
});

test('unresolved threads mapping', async () => {
  const { gh, fake } = client({
    'POST /graphql': {
      body: {
        data: {
          repository: {
            pullRequest: {
              reviewThreads: {
                nodes: [
                  { isResolved: true, path: 'a.js', comments: { nodes: [{ url: 'u1', author: { login: 'x' } }] } },
                  { isResolved: false, path: 'b.js', comments: { nodes: [{ url: 'u2', author: { login: 'copilot' } }] } },
                  { isResolved: false, path: 'c.js', comments: { nodes: [{ url: 'u3', author: null }] } },
                ],
              },
            },
          },
        },
      },
    },
  });
  assert.deepEqual(await gh.listUnresolvedThreads(12), [
    { url: 'u2', path: 'b.js', author: 'copilot' },
    { url: 'u3', path: 'c.js', author: null },
  ]);
  assert.deepEqual(fake.calls[0].body.variables, { owner: 'acme', name: 'app', number: 12 });
  assert.match(fake.calls[0].body.query, /reviewThreads\(first:100\)/);
});

test('enableAutoMerge sends the GraphQL mutation', async () => {
  const { gh, fake } = client({
    'POST /graphql': [
      { body: { data: { enablePullRequestAutoMerge: { clientMutationId: null } } } },
      { body: { errors: [{ message: 'Auto merge is not allowed for this repository' }] } },
    ],
  });
  await gh.enableAutoMerge('PR_kw1', 'squash');
  assert.match(fake.calls[0].body.query, /enablePullRequestAutoMerge\(input:\{pullRequestId:\$id,mergeMethod:\$method\}\)/);
  assert.deepEqual(fake.calls[0].body.variables, { id: 'PR_kw1', method: 'SQUASH' });
  await assert.rejects(gh.enableAutoMerge('PR_kw1', 'MERGE'), /Auto merge is not allowed/);
  await assert.rejects(gh.enableAutoMerge('PR_kw1', 'REBASE'), /SQUASH or MERGE/);
});

test('getJobLog returns text', async () => {
  const { gh, fake } = client({
    [`GET ${R}/actions/jobs/55/logs`]: { status: 302, headers: { location: 'https://logs.example.test/job/55?sig=s' } },
    'GET /job/55?sig=s': { body: 'DEPLOY_REF: uat-261016-1900\ngate_failure_class=none\n' },
  });
  assert.equal(await gh.getJobLog(55), 'DEPLOY_REF: uat-261016-1900\ngate_failure_class=none\n');
  assert.equal(fake.calls[1].headers.authorization, undefined);
});

test('list endpoints unwrap wrapped pages and build queries', async () => {
  const { gh } = client({
    [`GET ${R}/commits/abc/check-runs?per_page=100`]: { body: { total_count: 1, check_runs: [{ name: 'ci' }] } },
    [`GET ${R}/actions/workflows/deploy-uat.yml/runs?branch=main&event=push&per_page=20`]: {
      body: { total_count: 1, workflow_runs: [{ id: 1 }] },
    },
    [`GET ${R}/pulls?base=main&head=acme:cursor/x-p1&per_page=100&state=open`]: { body: [{ number: 8 }] },
  });
  assert.deepEqual(await gh.listCheckRuns('abc'), [{ name: 'ci' }]);
  assert.deepEqual(
    await gh.listWorkflowRuns('deploy-uat.yml', { branch: 'main', event: 'push', per_page: 20, pages: 1 }),
    [{ id: 1 }],
  );
  assert.deepEqual(await gh.listPulls({ head: 'cursor/x-p1', base: 'main', state: 'open' }), [{ number: 8 }]);
});

test('listIssues sends labels and state and drops pull requests', async () => {
  const { gh, fake } = client({
    [`GET ${R}/issues?labels=execute-plan,plan:abc&per_page=100&state=open`]: {
      body: [{ number: 1 }, { number: 2, pull_request: {} }, { number: 3 }],
    },
  });
  const issues = await gh.listIssues({ labels: ['execute-plan', 'plan:abc'] });
  assert.deepEqual(issues.map((i) => i.number), [1, 3]);
  assert.equal(fake.calls.length, 1);
});

test('createIssue posts title, body and labels', async () => {
  const { gh, fake } = client({ [`POST ${R}/issues`]: { status: 201, body: { number: 9 } } });
  const issue = await gh.createIssue({ title: 'T', body: 'B', labels: ['execute-plan'] });
  assert.equal(issue.number, 9);
  assert.deepEqual(fake.calls[0].body, { title: 'T', body: 'B', labels: ['execute-plan'] });
});

test('updateIssue patches only the given fields', async () => {
  const { gh, fake } = client({ [`PATCH ${R}/issues/9`]: { body: { number: 9 } } });
  await gh.updateIssue(9, { body: 'new', state: 'closed' });
  assert.deepEqual(fake.calls[0].body, { body: 'new', state: 'closed' });
});

test('fake fetch throws on unrecorded request', async () => {
  const fake = createFakeFetch({});
  await assert.rejects(
    fake('https://api.github.com/repos/acme/app/issues?state=open&labels=a', { method: 'GET' }),
    { message: 'Unrecorded request: GET /repos/acme/app/issues?labels=a&state=open' },
  );
  assert.equal(fake.calls.length, 1);
});
