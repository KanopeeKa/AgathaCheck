import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, '..', '..');

const POLICY = path.join(REPO_ROOT, 'docs/agent-efficiency/autonomous-pr-policy.md');
const POLICY_SECTION = /## CI retry budget[\s\S]*?(?=\n---\n)/;

/** Patterns that look like a standalone push/retry budget (not allowed outside policy). */
const FORBIDDEN_BUDGET_RE =
  /(?:same check red on|max\s+\*{0,2}\d+\s*(?:red\s+)?push|streak\s+\*{0,2}\d+\s+on|CI retry budget|Max iterations\s*\|)/i;

const SKILL_RULE_DIRS = [
  path.join(REPO_ROOT, '.cursor/skills'),
  path.join(REPO_ROOT, '.cursor/rules'),
];

function walkMarkdown(dir, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const name of fs.readdirSync(dir)) {
    const p = path.join(dir, name);
    const st = fs.statSync(p);
    if (st.isDirectory()) walkMarkdown(p, out);
    else if (name.endsWith('.md') || name.endsWith('.mdc')) out.push(p);
  }
  return out;
}

test('autonomous-pr-policy defines the canonical CI retry budget section', () => {
  const text = fs.readFileSync(POLICY, 'utf8');
  assert.match(text, /red push/i);
  assert.match(text, /same signature/i);
  assert.match(text, /streak/i);
});

test('skills and rules do not restate numeric CI push budgets (link to policy)', () => {
  const policyText = fs.readFileSync(POLICY, 'utf8');
  const section = policyText.match(POLICY_SECTION)?.[0] ?? '';
  assert.ok(section.length > 50, 'policy section missing');

  for (const file of walkMarkdown(SKILL_RULE_DIRS)) {
    if (file.includes('autonomous-pr-policy.md')) continue;
    const rel = path.relative(REPO_ROOT, file);
    const text = fs.readFileSync(file, 'utf8');
    if (FORBIDDEN_BUDGET_RE.test(text)) {
      assert.match(
        text,
        /autonomous-pr-policy\.md.*§CI retry budget|§CI retry budget in.*autonomous-pr-policy/,
        `${rel} restates a CI budget without linking to autonomous-pr-policy §CI retry budget`,
      );
    }
  }
});
