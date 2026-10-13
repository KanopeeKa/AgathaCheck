'use strict';

/**
 * Gate I — agent instruction files (docs/agent-efficiency/agent-instructions.md). All findings WARN.
 *  R-I1 word / line budgets for always-loaded instruction text
 *  R-I2 Copilot path instructions: no glob characters in filenames, `applyTo:` present
 *  R-I3 Claude path rules: `paths:` present, cited `.cursor/rules/*.mdc` exists
 *  R-I4 repo paths cited in agent entry files exist
 *  R-I5 forbidden closers (quoted in AGENTS.md) restated in other instruction files
 *  R-I6 retired terms (composer-2.5 outside Cursor files; Bugbot as an active reviewer)
 */
const fs = require('fs');
const path = require('path');
const { SEVERITY } = require('./constants');

const INSTRUCTION_PREFIXES = [
  '.claude/',
  '.cursor/rules/',
  '.cursor/skills/',
  '.cursor/commands/',
  '.cursor/agent-kernel/',
  '.github/instructions/',
  '.agents/memory/',
  'docs/agent-efficiency/',
];
const INSTRUCTION_FILES = ['AGENTS.md', 'CLAUDE.md', 'replit.md', '.github/copilot-instructions.md'];
const ENTRY_FILES = ['AGENTS.md', 'CLAUDE.md', 'replit.md', '.github/copilot-instructions.md'];

const BUDGETS = [
  { label: 'AGENTS.md', files: () => ['AGENTS.md'], words: 1300 },
  { label: 'CLAUDE.md (own text)', files: () => ['CLAUDE.md'], words: 450, skipImports: true },
  { label: 'Claude always-loaded set', files: (root) => claudeSet(root), words: 2500 },
  { label: 'Cursor always-loaded set', files: (root) => cursorSet(root), words: 2400 },
  { label: '.github/copilot-instructions.md', files: () => ['.github/copilot-instructions.md'], words: 350 },
  { label: 'replit.md', files: () => ['replit.md'], words: 900 },
];
const SKILL_LINE_TARGET = 300;

const COMPOSER_ALLOWED = [
  '.cursor/',
  'CLAUDE.md',
  '.claude/',
  'docs/agent-efficiency/pr-review-cost-efficiency.md',
  'docs/agent-efficiency/agent-instructions.md',
  'docs/agent-efficiency/execute-plan-instruction-stack.md',
];

function isInstructionFile(relPath) {
  if (!relPath.endsWith('.md') && !relPath.endsWith('.mdc')) return false;
  return INSTRUCTION_FILES.includes(relPath) || INSTRUCTION_PREFIXES.some((p) => relPath.startsWith(p));
}

function read(root, relPath) {
  const full = path.join(root, relPath);
  return fs.existsSync(full) ? fs.readFileSync(full, 'utf8') : null;
}

function splitFrontmatter(text) {
  const m = text.match(/^---\n([\s\S]*?)\n---\n?/);
  return m ? { fm: m[1], body: text.slice(m[0].length) } : { fm: '', body: text };
}

function words(text, skipImports) {
  const body = splitFrontmatter(text).body;
  const lines = skipImports ? body.split('\n').filter((l) => !/^@\S+/.test(l)) : body.split('\n');
  return lines.join(' ').split(/\s+/).filter(Boolean).length;
}

function claudeSet(root) {
  const text = read(root, 'CLAUDE.md');
  if (text === null) return [];
  const imports = (text.match(/^@(\S+)$/gm) || []).map((l) => l.slice(1));
  return ['CLAUDE.md', ...imports];
}

function cursorSet(root) {
  const dir = path.join(root, '.cursor/rules');
  const always = fs.existsSync(dir)
    ? fs
        .readdirSync(dir)
        .filter((f) => f.endsWith('.mdc'))
        .map((f) => `.cursor/rules/${f}`)
        .filter((f) => /^alwaysApply:\s*true/m.test(splitFrontmatter(read(root, f)).fm))
    : [];
  return ['AGENTS.md', ...always];
}

function listFiles(root, relDir, pred) {
  const full = path.join(root, relDir);
  if (!fs.existsSync(full)) return [];
  const out = [];
  for (const e of fs.readdirSync(full, { withFileTypes: true })) {
    const rel = `${relDir}/${e.name}`;
    if (e.isDirectory()) out.push(...listFiles(root, rel, pred));
    else if (pred(rel)) out.push(rel);
  }
  return out;
}

function allInstructionFiles(root) {
  const files = INSTRUCTION_FILES.filter((f) => fs.existsSync(path.join(root, f)));
  for (const p of INSTRUCTION_PREFIXES) files.push(...listFiles(root, p.replace(/\/$/, ''), isInstructionFile));
  return files;
}

function warn(ruleId, file, message, line) {
  return { ruleId, severity: SEVERITY.WARN, file, line, message };
}

function checkBudgets(root) {
  const out = [];
  for (const b of BUDGETS) {
    const files = b.files(root).filter((f) => read(root, f) !== null);
    if (!files.length) continue;
    const total = files.reduce((n, f) => n + words(read(root, f), b.skipImports), 0);
    if (total > b.words) out.push(warn('R-I1', files[0], `${b.label}: ${total} words > budget ${b.words}.`));
  }
  for (const f of listFiles(root, '.cursor/skills', (r) => r.endsWith('/SKILL.md'))) {
    const n = read(root, f).split('\n').length;
    if (n > SKILL_LINE_TARGET) out.push(warn('R-I1', f, `${n} lines > skill target ${SKILL_LINE_TARGET}.`));
  }
  return out;
}

function checkCopilot(root) {
  return listFiles(root, '.github/instructions', () => true).flatMap((f) => {
    const out = [];
    if (/[*?[\]{}]/.test(path.basename(f))) out.push(warn('R-I2', f, 'Filename contains glob characters.'));
    if (!/^applyTo:/m.test(splitFrontmatter(read(root, f)).fm)) {
      out.push(warn('R-I2', f, 'Missing `applyTo:` frontmatter — Copilot never applies this file.'));
    }
    return out;
  });
}

function checkClaudeRules(root) {
  return listFiles(root, '.claude/rules', (r) => r.endsWith('.md')).flatMap((f) => {
    const text = read(root, f);
    const out = [];
    if (!/^paths:/m.test(splitFrontmatter(text).fm)) out.push(warn('R-I3', f, 'Missing `paths:` frontmatter.'));
    for (const src of text.match(/\.cursor\/rules\/[\w.-]+\.mdc/g) || []) {
      if (!fs.existsSync(path.join(root, src))) out.push(warn('R-I3', f, `Points at missing ${src}.`));
    }
    return out;
  });
}

function checkCitedPaths(root) {
  const out = [];
  const entries = [...ENTRY_FILES, ...listFiles(root, '.claude', (r) => r.endsWith('.md'))];
  for (const f of entries) {
    const text = read(root, f);
    if (text === null) continue;
    for (const m of text.matchAll(/`([^`\s]+)`/g)) {
      const token = m[1].replace(/[.,;:)]+$/, '').split('#')[0];
      if (!token.includes('/') || /[*<>|{}$]/.test(token) || token.startsWith('/')) continue;
      const first = token.split('/')[0];
      if (!first || !fs.existsSync(path.join(root, first))) continue;
      if (!fs.existsSync(path.join(root, token))) out.push(warn('R-I4', f, `Cited path does not exist: ${token}`));
    }
  }
  return out;
}

function forbiddenClosers(root) {
  const line = (read(root, 'AGENTS.md') || '').split('\n').find((l) => /Forbidden closers/.test(l)) || '';
  return [...line.matchAll(/"([^"]+)"/g)].map((m) => m[1].toLowerCase());
}

function checkPhrases(root, files) {
  const out = [];
  const closers = forbiddenClosers(root);
  for (const f of files) {
    if (f === 'AGENTS.md' || f === 'docs/agent-efficiency/agent-instructions.md') continue;
    const lines = read(root, f).split('\n');
    lines.forEach((l, i) => {
      const lower = l.toLowerCase();
      const hit = closers.find((c) => lower.includes(c));
      if (hit) out.push(warn('R-I5', f, `Restates forbidden closer "${hit}" — link to AGENTS.md §Execute-plan.`, i + 1));
      if (lower.includes('composer-2.5') && !COMPOSER_ALLOWED.some((p) => f === p || f.startsWith(p))) {
        out.push(warn('R-I6', f, '`composer-2.5` is Cursor-only — keep it in pr-review-cost-efficiency.md.', i + 1));
      }
      if (/bugbot/.test(lower) && !/retired|disabled/.test(lower)) {
        out.push(warn('R-I6', f, 'Bugbot is retired — remove or mark as retired.', i + 1));
      }
    });
  }
  return out;
}

function runGateInstructions(ctx) {
  const { root, diff, scopeAll } = ctx;
  if (!scopeAll) {
    const touched = [...diff.added, ...diff.modified, ...(diff.deleted || [])].some(isInstructionFile);
    if (!touched) return [];
  }
  const files = allInstructionFiles(root);
  return [
    ...checkBudgets(root),
    ...checkCopilot(root),
    ...checkClaudeRules(root),
    ...checkCitedPaths(root),
    ...checkPhrases(root, files),
  ];
}

module.exports = { runGateInstructions, isInstructionFile, forbiddenClosers };
