'use strict';

/**
 * Execute-plan v2 approval: canonical JSON, approval_hash, control-issue comments.
 * Spec: docs/agent-efficiency/plans/execute-plan-v2/contracts.md §3.3, §3.4.
 */

const crypto = require('crypto');

const PLAN = '[a-z0-9][a-z0-9-]{2,48}';
const UNTIL = '\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z';
const APPROVE_RE = new RegExp(`^approve-autonomous (?<plan>${PLAN}) sha256:(?<hash>[0-9a-f]{64}) until (?<until>${UNTIL})$`);
const RESUME_RE = new RegExp(`^resume-autonomous (?<plan>${PLAN}) sha256:(?<hash>[0-9a-f]{64}) until (?<until>${UNTIL})$`);
const REVOKE_RE = new RegExp(`^revoke-autonomous (?<plan>${PLAN})$`);

const MAX_RESUME_MS = 14 * 24 * 60 * 60 * 1000;

function canonical(value) {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`;
  if (value && typeof value === 'object') {
    const keys = Object.keys(value).sort();
    return `{${keys.map((k) => `${JSON.stringify(k)}:${canonical(value[k])}`).join(',')}}`;
  }
  return JSON.stringify(value);
}

function computeApprovalHash(snapshot) {
  const input = { ...snapshot };
  delete input.approval_hash;
  return `sha256:${crypto.createHash('sha256').update(canonical(input), 'utf8').digest('hex')}`;
}

function parseControlComment(body) {
  const text = String(body == null ? '' : body).trim();
  let m = APPROVE_RE.exec(text);
  if (m) return { verb: 'approve', plan: m.groups.plan, hash: m.groups.hash, until: m.groups.until };
  m = RESUME_RE.exec(text);
  if (m) return { verb: 'resume', plan: m.groups.plan, hash: m.groups.hash, until: m.groups.until };
  m = REVOKE_RE.exec(text);
  if (m) return { verb: 'revoke', plan: m.groups.plan };
  return null;
}

/** @returns {{ valid: boolean, reason: null|string, verb: string|null, until: string|null }} */
function validateControlComment({ comment, snapshot, config }) {
  const parsed = parseControlComment(comment && comment.body);
  if (!parsed) return { valid: false, reason: 'plan', verb: null, until: null };
  const { verb } = parsed;
  const until = parsed.until || null;
  const result = (reason) => ({ valid: reason === null, reason, verb, until });

  const login = comment.user && comment.user.login;
  if (!config.owners.includes(login) || comment.author_association !== 'OWNER') return result('not-owner');
  if (login === config.bot_login) return result('bot');
  if (comment.created_at !== comment.updated_at) return result('edited');
  if (parsed.plan !== snapshot.plan_id) return result('plan');
  if (verb !== 'revoke' && parsed.hash !== snapshot.approval_hash.replace(/^sha256:/, '')) return result('hash');
  if (verb === 'approve' && until !== snapshot.approved_until) return result('until');
  if (verb !== 'revoke') {
    const created = Date.parse(comment.created_at);
    const end = Date.parse(until);
    if (end <= created) return result('until');
    if (verb === 'resume' && end > created + MAX_RESUME_MS) return result('window');
  }
  return result(null);
}

/** Latest approve/resume comment (valid or not) and the newest valid revoke. */
function findControlComments(comments, snapshot, config) {
  let authorizing = null;
  let revokeAt = null;
  const ordered = [...comments].sort((a, b) => Date.parse(a.created_at) - Date.parse(b.created_at));
  for (const comment of ordered) {
    const parsed = parseControlComment(comment.body);
    if (!parsed) continue;
    const res = validateControlComment({ comment, snapshot, config });
    if (parsed.verb === 'revoke') {
      if (res.valid) revokeAt = comment.created_at;
    } else {
      authorizing = {
        comment_id: comment.id,
        verb: parsed.verb,
        valid: res.valid,
        invalid_reason: res.reason,
        created_at: comment.created_at,
        until: parsed.until,
      };
    }
  }
  return { authorizing, revoke_comment_at: revokeAt };
}

module.exports = {
  APPROVE_RE,
  RESUME_RE,
  REVOKE_RE,
  canonical,
  computeApprovalHash,
  findControlComments,
  parseControlComment,
  validateControlComment,
};
