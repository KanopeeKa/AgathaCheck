'use strict';

/**
 * "Is this commit on main?" for deploy guards. Uses `compare(<sha>...main)` (status ahead or
 * identical), never `branches-where-head`, which only lists branches whose *tip* is the commit
 * and so rejects every commit once main has moved on.
 */

const ON_MAIN = new Set(['ahead', 'identical']);
const UAT_TAG = /^uat-\d{6}-\d+$/;

function stripRefPrefix(ref) {
  return String(ref || '').trim().replace(/^refs\/(heads|tags)\//, '');
}

async function commitIsOnMain(client, commitSha) {
  try {
    const { status } = await client.compare(commitSha, 'main');
    return ON_MAIN.has(status);
  } catch (e) {
    if (e && (e.status === 404 || e.status === 422)) return false;
    throw e;
  }
}

/** @returns {Promise<{ ok: boolean, code?: string, tag?: string, commitSha?: string }>} */
async function checkUatTagOnMain(client, ref) {
  const tag = stripRefPrefix(ref);
  if (!UAT_TAG.test(tag)) return { ok: false, code: 'not_a_uat_tag', tag };
  let commitSha;
  try {
    commitSha = await client.getCommitSha(`refs/tags/${tag}`);
  } catch (e) {
    if (e && (e.status === 404 || e.status === 422)) return { ok: false, code: 'tag_not_found', tag };
    throw e;
  }
  if (!(await commitIsOnMain(client, commitSha))) return { ok: false, code: 'commit_not_on_main', tag, commitSha };
  return { ok: true, tag, commitSha };
}

module.exports = { UAT_TAG, stripRefPrefix, commitIsOnMain, checkUatTagOnMain };
