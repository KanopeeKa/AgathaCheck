import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import {
  PET_ACTIVITY_HOOK_MANIFEST,
  PET_ACTIVITY_EVENT_TYPES,
} from '../../lib/petActivity.js';

const testFilePath = fileURLToPath(import.meta.url);
const testDir = path.dirname(testFilePath);
const repoRoot = path.resolve(testDir, '../../../');

function countMatches(source, pattern) {
  const re = new RegExp(pattern, 'g');
  return (source.match(re) || []).length;
}

describe('petActivityHooks contract', () => {
  it('manifest lists every required hook site with recordPetActivity calls', () => {
    expect(PET_ACTIVITY_HOOK_MANIFEST.length).toBeGreaterThan(0);

    for (const entry of PET_ACTIVITY_HOOK_MANIFEST) {
      const absolutePath = path.join(repoRoot, entry.file);
      expect(fs.existsSync(absolutePath)).toBe(true);

      const source = fs.readFileSync(absolutePath, 'utf8');
      expect(source).toMatch(/recordPetActivity|recordFosterSessionActivity/);

      const callCount = countMatches(
        source,
        'recordPetActivity(?:ForPet|Safe)?\\(|recordFosterSessionActivity\\(',
      );
      expect(callCount).toBeGreaterThanOrEqual(entry.minCalls ?? 1);

      if (entry.eventType) {
        expect(PET_ACTIVITY_EVENT_TYPES).toContain(entry.eventType);
      }
    }
  });

  it('does not allow duplicate manifest ids', () => {
    const ids = PET_ACTIVITY_HOOK_MANIFEST.map((entry) => entry.id);
    expect(new Set(ids).size).toBe(ids.length);
  });
});
