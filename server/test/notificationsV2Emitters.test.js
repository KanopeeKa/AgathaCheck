import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..', '..');

const SCAN_DIRS = [
  path.join(repoRoot, 'server/lib'),
  path.join(repoRoot, 'server/routes'),
  path.join(repoRoot, 'server/services'),
];

describe('notifications v2 PR3 emitters', () => {
  it('does not use banned type general in createNotification calls', () => {
    const offenders = [];
    for (const dir of SCAN_DIRS) {
      walk(dir, offenders);
    }
    expect(offenders).toEqual([]);
  });
});

function walk(dir, offenders) {
  if (!fs.existsSync(dir)) return;
  for (const name of fs.readdirSync(dir)) {
    const full = path.join(dir, name);
    const stat = fs.statSync(full);
    if (stat.isDirectory()) {
      walk(full, offenders);
      continue;
    }
    if (!name.endsWith('.js')) continue;
    const text = fs.readFileSync(full, 'utf8');
    if (!text.includes('createNotification')) continue;
    const rel = path.relative(repoRoot, full);
    for (const line of text.split('\n')) {
      if (line.includes('createNotification') && line.includes("'general'")) {
        offenders.push(`${rel}: ${line.trim()}`);
      }
      if (/type:\s*'general'/.test(line)) {
        offenders.push(`${rel}: ${line.trim()}`);
      }
    }
  }
}
