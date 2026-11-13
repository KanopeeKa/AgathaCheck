import { getSupportGithubRepo, getSupportGithubToken } from './config.js';
import { safeOutboxError } from './safeError.js';

function parseRepoSlug() {
  const slug = getSupportGithubRepo();
  if (!slug) return null;
  const parts = String(slug).trim().split('/');
  if (parts.length !== 2 || !parts[0] || !parts[1]) {
    return null;
  }
  return { owner: parts[0], repo: parts[1] };
}

function githubHeaders() {
  const token = getSupportGithubToken();
  const headers = {
    Accept: 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    'User-Agent': 'AgathaTrack-support-outbox',
  };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  return headers;
}

/**
 * @returns {Promise<{ ok: true, private: boolean } | { ok: false, reason: string }>}
 */
export async function fetchGithubRepoPrivacy() {
  const parsed = parseRepoSlug();
  if (!parsed) {
    return { ok: false, reason: 'SUPPORT_GITHUB_REPO unset or invalid' };
  }
  const { owner, repo } = parsed;
  const url = `https://api.github.com/repos/${encodeURIComponent(owner)}/${encodeURIComponent(repo)}`;
  try {
    const res = await fetch(url, { headers: githubHeaders() });
    if (res.status === 404) {
      return { ok: false, reason: `repo not found (${res.status})` };
    }
    if (!res.ok) {
      return { ok: false, reason: `repo metadata HTTP ${res.status}` };
    }
    const body = await res.json();
    if (body?.private !== true) {
      return { ok: false, reason: 'repo is not private' };
    }
    return { ok: true, private: true };
  } catch (err) {
    return { ok: false, reason: safeOutboxError(err?.message || 'github fetch failed') };
  }
}

/**
 * @returns {Promise<{ ok: true, number: number } | { ok: false, retryable: boolean, message: string, status?: number }>}
 */
export async function createGithubSupportIssue({ title, body, labels }) {
  const parsed = parseRepoSlug();
  if (!parsed) {
    return { ok: false, retryable: false, message: 'github repo not configured' };
  }
  const { owner, repo } = parsed;
  const url = `https://api.github.com/repos/${encodeURIComponent(owner)}/${encodeURIComponent(repo)}/issues`;
  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: { ...githubHeaders(), 'Content-Type': 'application/json' },
      body: JSON.stringify({ title, body, labels }),
    });
    if (res.status === 422) {
      const payload = await res.json().catch(() => ({}));
      const labelMsg = Array.isArray(payload?.errors)
        ? payload.errors.map((e) => e?.message).filter(Boolean).join('; ')
        : '';
      return {
        ok: false,
        retryable: false,
        message: safeOutboxError(labelMsg || `github create HTTP 422`),
        status: 422,
      };
    }
    if (!res.ok) {
      return {
        ok: false,
        retryable: res.status >= 500 || res.status === 429,
        message: safeOutboxError(`github create HTTP ${res.status}`),
        status: res.status,
      };
    }
    const created = await res.json();
    const number = Number(created?.number);
    if (!Number.isFinite(number)) {
      return { ok: false, retryable: true, message: 'github create missing issue number' };
    }
    return { ok: true, number };
  } catch (err) {
    return {
      ok: false,
      retryable: true,
      message: safeOutboxError(err?.message || 'github create failed'),
    };
  }
}

/**
 * @returns {Promise<{ ok: true } | { ok: false, retryable: boolean, message: string, status?: number }>}
 */
export async function redactGithubSupportIssue(issueNumber) {
  const parsed = parseRepoSlug();
  if (!parsed) {
    return { ok: false, retryable: false, message: 'github repo not configured' };
  }
  const { owner, repo } = parsed;
  const base = `https://api.github.com/repos/${encodeURIComponent(owner)}/${encodeURIComponent(repo)}/issues/${issueNumber}`;
  try {
    const patch = await fetch(base, {
      method: 'PATCH',
      headers: { ...githubHeaders(), 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: '[removed]', body: '[removed]' }),
    });
    if (!patch.ok) {
      return {
        ok: false,
        retryable: patch.status >= 500 || patch.status === 429,
        message: safeOutboxError(`github patch HTTP ${patch.status}`),
        status: patch.status,
      };
    }
    const labelRes = await fetch(`${base}/labels`, {
      method: 'POST',
      headers: { ...githubHeaders(), 'Content-Type': 'application/json' },
      body: JSON.stringify(['redacted']),
    });
    if (labelRes.status === 422) {
      return {
        ok: false,
        retryable: false,
        message: safeOutboxError('github redacted label missing (422)'),
        status: 422,
      };
    }
    if (!labelRes.ok && labelRes.status !== 404) {
      return {
        ok: false,
        retryable: labelRes.status >= 500,
        message: safeOutboxError(`github label HTTP ${labelRes.status}`),
        status: labelRes.status,
      };
    }
    return { ok: true };
  } catch (err) {
    return {
      ok: false,
      retryable: true,
      message: safeOutboxError(err?.message || 'github redact failed'),
    };
  }
}
