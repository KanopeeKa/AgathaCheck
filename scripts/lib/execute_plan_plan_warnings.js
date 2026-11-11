'use strict';

/**
 * Non-blocking warnings for execute-plan plan prose that implies cross-programme waits.
 * v2 phases cannot pause mid-plan for another programme; see parallel-programmes.md.
 */

const DOC = 'docs/agent-efficiency/parallel-programmes.md';

/** @type {{ id: string, re: RegExp, hint: string }[]} */
const CROSS_PLAN_WAIT_RULES = [
  {
    id: 'wait-for-programme',
    re: /\bwait for\b[^\n]{0,200}\b(?:programme|program\b|pre-?uat|landing slot|lands on [`']main|entry gate|another (?:child|plan)|integration branch)/i,
    hint: `execute-plan phases cannot wait on another programme mid-flight; serialise landings per ${DOC}`,
  },
  {
    id: 'wait-for-plan-id',
    re: /\bwait for\b[^\n]{0,120}`[a-z0-9][a-z0-9-]{2,48}`/i,
    hint: `use a roadmap child plan or parallel-programmes landing order instead of in-plan waits (${DOC})`,
  },
  {
    id: 'human-pause',
    re: /\bhuman_pause\b/i,
    hint: 'STOP/human_pause is for owner halts, not cross-plan sequencing — see execute-plan-v2 non-goals',
  },
  {
    id: 'entry-gate',
    re: /\bentry gate\b/i,
    hint: `child plan entry gates belong on roadmap control issues, not in-phase waits (${DOC})`,
  },
  {
    id: 'landing-slot',
    re: /\blanding slot\b/i,
    hint: `landing order is documented in ${DOC}; split plans rather than blocking a phase on a slot`,
  },
  {
    id: 'resume-plan-v1',
    re: /\bresume-plan\b/i,
    hint: 'v1 resume-plan is retired; use resume-autonomous on the control issue',
  },
];

function stripFencedBlocks(markdown) {
  const lines = String(markdown).replace(/\r\n/g, '\n').split('\n');
  const out = [];
  let inFence = false;
  for (const line of lines) {
    if (/^\s*```/.test(line)) {
      inFence = !inFence;
      continue;
    }
    if (!inFence) out.push(line);
  }
  return out.join('\n');
}

/**
 * @param {string} markdown plan file body
 * @param {{ log?: (msg: string) => void }} [opts]
 */
function warnCrossPlanWaitPhrases(markdown, opts = {}) {
  const log = opts.log || console.warn;
  const prose = stripFencedBlocks(markdown);
  for (const rule of CROSS_PLAN_WAIT_RULES) {
    const m = rule.re.exec(prose);
    if (!m) continue;
    const lineNo = prose.slice(0, m.index).split('\n').length;
    log(
      `validate_execute_plan_snapshot: warn: [${rule.id}] plan line ~${lineNo}: `
        + `${rule.hint} (matched: ${JSON.stringify(m[0].trim().slice(0, 120))})`,
    );
  }
}

module.exports = { CROSS_PLAN_WAIT_RULES, stripFencedBlocks, warnCrossPlanWaitPhrases };
