'use strict';

/**
 * Plan-linked side PR files merged to main (release-scope union for execute-plan v2).
 */

const UNBLOCKS_RE = /Unblocks:\s*plan\s+([a-z0-9][a-z0-9-]{2,48})\s+phase\s+\d+/i;

/**
 * Files touched by merged PRs to main whose body unblocks this plan (since epoch).
 * @returns {Promise<Set<string>>}
 */
async function supportFilesForPlan(client, planId, { since = null, pages = 3 } = {}) {
  const out = new Set();
  const pulls = await client.listPulls({ base: 'main', state: 'closed', sort: 'updated', direction: 'desc', pages });
  for (const pull of pulls) {
    if (!pull.merged_at) continue;
    if (since && Date.parse(pull.merged_at) <= Date.parse(since)) continue;
    const body = pull.body || '';
    const m = UNBLOCKS_RE.exec(body);
    if (!m || m[1] !== planId) continue;
    const files = await client.listPullFiles(pull.number);
    for (const f of files) {
      if (f.filename) out.add(f.filename);
      if (f.previous_filename) out.add(f.previous_filename);
    }
  }
  return out;
}

module.exports = { UNBLOCKS_RE, supportFilesForPlan };
