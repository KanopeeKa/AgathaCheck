import { readFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

import { describe, expect, it } from '@jest/globals';

import {
  evaluateVaccinationWelfare,
  vaccinationWelfareDedupeKey,
} from '../../../routes/careIntelligence/welfare/vaccinationWelfareEvaluator.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const fixtures = JSON.parse(
  readFileSync(join(__dirname, 'fixtures', 'vaccination.json'), 'utf8'),
);

describe('vaccination welfare evaluator (AC-WF-11)', () => {
  for (const fixture of fixtures) {
    it(`${fixture.id}`, () => {
      const candidate = evaluateVaccinationWelfare(fixture.pet, fixture.context);
      if (fixture.expectCandidate) {
        expect(candidate).not.toBeNull();
        expect(candidate.subject_key).toBe('vaccination_welfare');
        expect(candidate.dedupe_key).toBe(
          vaccinationWelfareDedupeKey(fixture.pet.id),
        );
      } else {
        expect(candidate).toBeNull();
      }
    });
  }
});
