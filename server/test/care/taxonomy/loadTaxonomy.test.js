import fs from 'fs';
import os from 'os';
import path from 'path';
import { afterEach, describe, expect, it } from '@jest/globals';
import { fileURLToPath } from 'url';
import { resolveTaxonomyPath } from '../../../lib/care/taxonomy/loadTaxonomy.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

describe('resolveTaxonomyPath', () => {
  let tmpDir;

  afterEach(() => {
    if (tmpDir) {
      fs.rmSync(tmpDir, { recursive: true, force: true });
      tmpDir = null;
    }
  });

  it('prefers the FTP bundle candidate when both paths exist', () => {
    tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'care-taxonomy-'));
    const bundlePath = path.join(tmpDir, 'backend-shared.json');
    const monorepoPath = path.join(tmpDir, 'repo-shared.json');
    fs.writeFileSync(bundlePath, '{}');
    fs.writeFileSync(monorepoPath, '{}');
    expect(resolveTaxonomyPath([bundlePath, monorepoPath])).toBe(bundlePath);
  });

  it('falls back to the monorepo candidate', () => {
    tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'care-taxonomy-'));
    const bundlePath = path.join(tmpDir, 'missing-bundle.json');
    const monorepoPath = path.join(tmpDir, 'repo-shared.json');
    fs.writeFileSync(monorepoPath, '{}');
    expect(resolveTaxonomyPath([bundlePath, monorepoPath])).toBe(monorepoPath);
  });

  it('throws when no candidate exists', () => {
    expect(() =>
      resolveTaxonomyPath([
        path.join(os.tmpdir(), 'care-taxonomy-missing-a.json'),
        path.join(os.tmpdir(), 'care-taxonomy-missing-b.json'),
      ]),
    ).toThrow(/care taxonomy file not found/);
  });

  it('lists server/shared before repo-root shared in default candidates', () => {
    const taxonomyDir = path.resolve(__dirname, '../../../lib/care/taxonomy');
    const bundleCandidate = path.resolve(taxonomyDir, '../../../shared/care_taxonomy.json');
    const monorepoCandidate = path.resolve(
      taxonomyDir,
      '../../../../shared/care_taxonomy.json',
    );
    expect(bundleCandidate).toMatch(/server[/\\]shared[/\\]care_taxonomy\.json$/);
    expect(monorepoCandidate).toMatch(/shared[/\\]care_taxonomy\.json$/);
    expect(fs.existsSync(monorepoCandidate)).toBe(true);
  });
});
