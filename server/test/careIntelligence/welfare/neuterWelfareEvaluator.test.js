import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

import { evaluateNeuterWelfare } from '../../../routes/careIntelligence/welfare/neuterWelfareEvaluator.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const fixtures = JSON.parse(
  readFileSync(join(__dirname, 'fixtures', 'neuter.json'), 'utf8'),
);

describe('neuter welfare evaluator (PR-08)', () => {
  for (const fixture of fixtures) {
    test(`fixture ${fixture.id}`, () => {
      const candidate = evaluateNeuterWelfare(fixture.pet);
      if (fixture.expectCandidate) {
        expect(candidate).not.toBeNull();
        expect(candidate.subject_key).toBe('neuter_welfare');
        expect(candidate.dedupe_key).toBe(`welfare:neuter:${fixture.pet.id}`);
        expect(candidate.rationale_key).toBe('careWelfareNeuterWhy');
      } else {
        expect(candidate).toBeNull();
      }
    });
  }
});
