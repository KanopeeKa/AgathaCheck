import { readFileSync, readdirSync, statSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import { describe, expect, it } from '@jest/globals';

const occurrenceRoot = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  '../../lib/care/occurrence',
);

const forbidden = [
  'weightObservationRepository',
  'weight_entries',
];

function walk(dir, files = []) {
  for (const name of readdirSync(dir)) {
    const full = path.join(dir, name);
    if (statSync(full).isDirectory()) walk(full, files);
    else if (name.endsWith('.js')) files.push(full);
  }
  return files;
}

describe('care occurrence engine observation boundary (§5.5b)', () => {
  it('does not import weight observation SQL paths', () => {
    const violations = [];
    for (const file of walk(occurrenceRoot)) {
      const text = readFileSync(file, 'utf8');
      for (const token of forbidden) {
        if (text.includes(token)) {
          violations.push(`${path.relative(occurrenceRoot, file)}: ${token}`);
        }
      }
    }
    expect(violations).toEqual([]);
  });
});
