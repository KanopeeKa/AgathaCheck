'use strict';

/**
 * Execute-plan v2 GitHub client (REST + GraphQL), Node built-ins only.
 * The only path for GitHub access in v2 code — no `gh`. Tests inject `fetchImpl`
 * (scripts/test/helpers/execute_plan_fake_fetch.js) and `sleep`.
 */

const DEFAULT_BASE_URL = 'https://api.github.com';
const RETRY_DELAYS_MS = [2000, 4000, 8000];
const RETRY_STATUSES = new Set([502, 503, 504]);
const REQUEST_TIMEOUT_MS = 30_000; // a hung call must not hold the driver until the job timeout
const PULL_FILES_LIMIT = 3000;

class MissingToken extends Error {
  constructor(message = 'No GitHub token: set EXECUTE_PLAN_TOKEN, GH_TOKEN or GITHUB_TOKEN') {
    super(message);
    this.name = 'MissingToken';
  }
}

class RateLimited extends Error {
  constructor(message, resetAt) {
    super(message);
    this.name = 'RateLimited';
    /** @type {string} ISO time of x-ratelimit-reset */
    this.resetAt = resetAt;
  }
}

class PullFilesOverflow extends Error {
  constructor(message) {
    super(message);
    this.name = 'PullFilesOverflow';
  }
}

class GitHubError extends Error {
  constructor(status, message) {
    super(message);
    this.name = 'GitHubError';
    /** @type {number} */
    this.status = status;
  }
}

function resolveToken(explicit, env = process.env) {
  return explicit || env.EXECUTE_PLAN_TOKEN || env.GH_TOKEN || env.GITHUB_TOKEN || null;
}

function parseNextLink(header) {
  if (!header) return null;
  for (const part of header.split(',')) {
    const m = part.match(/<([^>]+)>\s*;\s*rel="next"/);
    if (m) return m[1];
  }
  return null;
}

function resetAtFrom(headers) {
  const reset = Number(headers.get('x-ratelimit-reset'));
  return Number.isFinite(reset) && reset > 0 ? new Date(reset * 1000).toISOString() : null;
}

function buildQuery(query) {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query || {})) {
    if (value !== undefined && value !== null && value !== '') params.set(key, String(value));
  }
  const text = params.toString();
  return text ? `?${text}` : '';
}

async function readBody(res) {
  const text = await res.text();
  if (!text) return { text, data: null };
  try {
    return { text, data: JSON.parse(text) };
  } catch {
    return { text, data: null };
  }
}

/**
 * @param {{ repo: string, token?: string, fetchImpl?: typeof fetch, baseUrl?: string, sleep?: (ms:number)=>Promise<void> }} opts
 */
function createGitHubClient(opts) {
  const { repo, token: explicitToken } = opts || {};
  if (!/^[^/\s]+\/[^/\s]+$/.test(repo || '')) {
    throw new Error(`createGitHubClient: repo must be 'owner/name' (got ${JSON.stringify(repo)})`);
  }
  const [owner, name] = repo.split('/');
  const fetchImpl = opts.fetchImpl || globalThis.fetch;
  const baseUrl = (opts.baseUrl || DEFAULT_BASE_URL).replace(/\/+$/, '');
  const sleep = opts.sleep || ((ms) => new Promise((resolve) => setTimeout(resolve, ms)));
  const repoPath = `/repos/${owner}/${name}`;

  function headers(token) {
    return {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'execute-plan/2',
    };
  }

  /**
   * One HTTP exchange with retries. `target` is an API path or an absolute URL (Link pages).
   * @returns {Promise<{ status: number, headers: Headers, data: any, text: string }>}
   */
  async function send(method, target, { body, nullOn404 = false, redirect } = {}) {
    const token = resolveToken(explicitToken);
    if (!token) throw new MissingToken();
    const url = /^https?:\/\//.test(target) ? target : `${baseUrl}${target}`;
    const label = `${method} ${new URL(url).pathname}`;
    // Absolute targets come from Link headers; the token only ever goes to the API origin.
    if (new URL(url).origin !== new URL(baseUrl).origin) {
      throw new GitHubError(0, `${label}: refusing to send the token to another origin`);
    }
    const init = { method, headers: headers(token) };
    if (body !== undefined) {
      init.body = JSON.stringify(body);
      init.headers['Content-Type'] = 'application/json';
    }
    if (redirect) init.redirect = redirect;

    for (let attempt = 0; ; attempt += 1) {
      // Timeouts reject and propagate; they are never retried.
      const res = await fetchImpl(url, { ...init, signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS) });
      if (res.status >= 300 && res.status < 400 && redirect === 'manual') {
        return { status: res.status, headers: res.headers, data: null, text: '' };
      }
      const { text, data } = await readBody(res);
      if (res.ok) return { status: res.status, headers: res.headers, data, text };
      if (res.status === 404 && nullOn404) return { status: 404, headers: res.headers, data: null, text };

      if ((res.status === 403 || res.status === 429) && res.headers.get('x-ratelimit-remaining') === '0') {
        const resetAt = resetAtFrom(res.headers);
        throw new RateLimited(`${label}: rate limit exhausted (resets ${resetAt || 'unknown'})`, resetAt);
      }
      const secondary =
        (res.status === 403 || res.status === 429) && /secondary rate limit/i.test(text);
      if ((RETRY_STATUSES.has(res.status) || secondary) && attempt < RETRY_DELAYS_MS.length) {
        await sleep(RETRY_DELAYS_MS[attempt]);
        continue;
      }
      const detail = data && typeof data.message === 'string' ? data.message : res.statusText;
      throw new GitHubError(res.status, `${label} failed with ${res.status}${detail ? `: ${detail}` : ''}`);
    }
  }

  async function rest(method, path, options) {
    return (await send(method, `${repoPath}${path}`, options)).data;
  }

  /** Follows `Link: rel="next"`; `itemsKey` unwraps `{ total_count, <key>: [] }` pages. */
  async function paginate(path, { query, pages, itemsKey } = {}) {
    const items = [];
    let target = `${repoPath}${path}${buildQuery({ per_page: 100, ...query })}`;
    for (let page = 0; target && (pages === undefined || page < pages); page += 1) {
      const res = await send('GET', target);
      const chunk = itemsKey ? (res.data && res.data[itemsKey]) || [] : res.data || [];
      items.push(...chunk);
      target = parseNextLink(res.headers.get('link'));
    }
    return items;
  }

  async function graphql(query, variables) {
    const res = await send('POST', '/graphql', { body: { query, variables } });
    const errors = res.data && res.data.errors;
    if (Array.isArray(errors) && errors.length > 0) {
      throw new GitHubError(res.status, `POST /graphql failed: ${errors.map((e) => e.message).join('; ')}`);
    }
    return res.data && res.data.data;
  }

  const enc = encodeURIComponent;

  return {
    repo,

    /** The account the token belongs to (`GET /user`). */
    getAuthenticatedUser: async () => (await send('GET', '/user')).data,

    // Issues, comments, labels
    getIssue: (n) => rest('GET', `/issues/${n}`),
    createIssue: ({ title, body, labels }) => rest('POST', '/issues', { body: { title, body, labels } }),
    updateIssue: (n, { title, body, state, labels } = {}) => {
      const patch = { title, body, state, labels };
      for (const key of Object.keys(patch)) if (patch[key] === undefined) delete patch[key];
      return rest('PATCH', `/issues/${n}`, { body: patch });
    },
    closeIssue: (n) => rest('PATCH', `/issues/${n}`, { body: { state: 'closed' } }),
    listIssueComments: (n, { pages } = {}) => paginate(`/issues/${n}/comments`, { pages }),
    createComment: (n, body) => rest('POST', `/issues/${n}/comments`, { body: { body } }),
    updateComment: (id, body) => rest('PATCH', `/issues/comments/${id}`, { body: { body } }),
    addLabels: (n, labels) => rest('POST', `/issues/${n}/labels`, { body: { labels } }),
    async removeLabel(n, label) {
      await rest('DELETE', `/issues/${n}/labels/${enc(label)}`, { nullOn404: true });
    },
    /** Issues only (items carrying `pull_request` are dropped); `labels` is an array joined with commas. */
    async listIssues({ labels, state = 'open', pages } = {}) {
      const query = { state, labels: Array.isArray(labels) ? labels.join(',') : labels };
      const items = await paginate('/issues', { pages, query });
      return items.filter((item) => !item.pull_request);
    },
    listIssueTimeline: (n, { pages } = {}) => paginate(`/issues/${n}/timeline`, { pages }),

    // Pull requests
    listPulls: ({ head, base, state, pages } = {}) =>
      paginate('/pulls', { pages, query: { head: head ? `${owner}:${head}` : undefined, base, state } }),
    getPull: (n) => rest('GET', `/pulls/${n}`),
    listPullCommits: (n, { pages } = {}) => paginate(`/pulls/${n}/commits`, { pages }),
    listPullReviews: (n, { pages } = {}) => paginate(`/pulls/${n}/reviews`, { pages }),
    async listPullFiles(n) {
      const files = await paginate(`/pulls/${n}/files`);
      // The API stops at 3000 files; at the cap, the PR's own count says whether some are missing.
      if (files.length >= PULL_FILES_LIMIT) {
        const pull = await rest('GET', `/pulls/${n}`);
        const total = Math.max(files.length, Number(pull && pull.changed_files) || 0);
        if (total > PULL_FILES_LIMIT) {
          throw new PullFilesOverflow(`PR #${n} changes ${total} files; the API lists at most ${PULL_FILES_LIMIT}`);
        }
      }
      return files;
    },
    createPull: ({ title, head, base, body, draft = false }) =>
      rest('POST', '/pulls', { body: { title, head, base, body, draft } }),
    mergePull: (n, { method = 'squash' } = {}) =>
      rest('PUT', `/pulls/${n}/merge`, { body: { merge_method: method } }),
    updateBranch: (n) => rest('PUT', `/pulls/${n}/update-branch`, { body: {} }),

    async listUnresolvedThreads(n) {
      const data = await graphql(
        `query($owner:String!,$name:String!,$number:Int!){repository(owner:$owner,name:$name){pullRequest(number:$number){reviewThreads(first:100){nodes{isResolved path comments(first:1){nodes{url author{login}}}}}}}}`,
        { owner, name, number: Number(n) },
      );
      const pr = data && data.repository && data.repository.pullRequest;
      if (!pr) throw new GitHubError(404, `POST /graphql: pull request #${n} not found`);
      return pr.reviewThreads.nodes
        .filter((t) => !t.isResolved)
        .map((t) => {
          const first = (t.comments && t.comments.nodes && t.comments.nodes[0]) || {};
          return { url: first.url || null, path: t.path || null, author: (first.author && first.author.login) || null };
        });
    },
    async enableAutoMerge(nodeId, method = 'SQUASH') {
      const mergeMethod = String(method).toUpperCase();
      if (mergeMethod !== 'SQUASH' && mergeMethod !== 'MERGE') {
        throw new Error(`enableAutoMerge: method must be SQUASH or MERGE (got ${method})`);
      }
      return graphql(
        `mutation($id:ID!,$method:PullRequestMergeMethod!){enablePullRequestAutoMerge(input:{pullRequestId:$id,mergeMethod:$method}){clientMutationId}}`,
        { id: nodeId, method: mergeMethod },
      );
    },
    disableAutoMerge: (nodeId) =>
      graphql(
        `mutation($id:ID!){disablePullRequestAutoMerge(input:{pullRequestId:$id}){clientMutationId}}`,
        { id: nodeId },
      ),

    // Checks
    listCheckRuns: (sha, { pages } = {}) =>
      paginate(`/commits/${sha}/check-runs`, { pages, itemsKey: 'check_runs' }),
    createCheckRun: ({ name: checkName, head_sha, conclusion, title, summary }) =>
      rest('POST', '/check-runs', {
        body: { name: checkName, head_sha, status: 'completed', conclusion, output: { title, summary } },
      }),
    updateCheckRun(id, { conclusion, title, summary, ...extra } = {}) {
      const body = { ...extra };
      if (conclusion !== undefined) Object.assign(body, { status: 'completed', conclusion });
      if (title !== undefined || summary !== undefined) body.output = { title, summary };
      return rest('PATCH', `/check-runs/${id}`, { body });
    },

    // Commits, refs, contents
    async compare(base, head) {
      const data = await rest('GET', `/compare/${enc(base)}...${enc(head)}`);
      return {
        status: data.status,
        ahead_by: data.ahead_by,
        behind_by: data.behind_by,
        files: (data.files || []).map((f) => ({ filename: f.filename, status: f.status })),
      };
    },
    /** Commit SHA a branch, tag (annotated tags are peeled) or SHA resolves to. */
    getCommitSha: async (ref) => (await rest('GET', `/commits/${String(ref).split('/').map(enc).join('/')}`)).sha,
    listTags: ({ pages } = {}) => paginate('/tags', { pages }),
    getBranch: (branch) => rest('GET', `/branches/${enc(branch)}`, { nullOn404: true }),
    createRef: (ref, sha) => rest('POST', '/git/refs', { body: { ref, sha } }),
    async getFileAtRef(path, ref) {
      const encodedPath = path.split('/').map(enc).join('/');
      const data = await rest('GET', `/contents/${encodedPath}${buildQuery({ ref })}`, { nullOn404: true });
      if (!data) return null;
      if (Array.isArray(data) || data.type !== 'file') {
        throw new GitHubError(422, `GET contents/${path}: not a file`);
      }
      return { content: Buffer.from(data.content || '', data.encoding || 'base64').toString('utf8'), sha: data.sha };
    },

    // Actions
    listWorkflowRuns: (file, { branch, event, status, per_page = 100, pages } = {}) =>
      paginate(`/actions/workflows/${enc(file)}/runs`, {
        pages,
        itemsKey: 'workflow_runs',
        query: { branch, event, status, per_page },
      }),
    getWorkflowRun: (runId) => rest('GET', `/actions/runs/${enc(runId)}`),
    listRunJobs: (runId, { pages } = {}) => paginate(`/actions/runs/${runId}/jobs`, { pages, itemsKey: 'jobs' }),
    async getJobLog(jobId) {
      const first = await send('GET', `${repoPath}/actions/jobs/${jobId}/logs`, { redirect: 'manual' });
      if (first.status < 300) return first.text;
      const location = first.headers.get('location');
      if (!location) throw new GitHubError(first.status, `GET job ${jobId} logs: redirect without location`);
      // The signed log URL must not receive the token.
      const res = await fetchImpl(new URL(location, baseUrl).toString(), {
        method: 'GET',
        signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      });
      if (!res.ok) throw new GitHubError(res.status, `GET job ${jobId} logs (download) failed with ${res.status}`);
      return res.text();
    },
    async dispatchWorkflow(file, ref, inputs = {}) {
      await rest('POST', `/actions/workflows/${enc(file)}/dispatches`, { body: { ref, inputs } });
    },
  };
}

module.exports = {
  createGitHubClient,
  MissingToken,
  RateLimited,
  PullFilesOverflow,
  GitHubError,
  resolveToken,
  parseNextLink,
  DEFAULT_BASE_URL,
  RETRY_DELAYS_MS,
  REQUEST_TIMEOUT_MS,
};
