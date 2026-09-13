import { describe, expect, it } from '@jest/globals';

import { evaluateWeightEstablishment } from '../../../lib/care/progression/weightEstablishmentPolicy.js';
import { DEMO_IDS } from '../../../db/seeds/demo-constants.js';
import { careItemModelWeightEstablishmentFacts } from '../../../db/seeds/scenarios/care-item-model-fixture.js';

describe('care-item-model-fixture seed facts', () => {
  it('reports established for the seeded weekly weight monitoring item', () => {
    const facts = careItemModelWeightEstablishmentFacts();
    const result = evaluateWeightEstablishment(
      DEMO_IDS.buddyPet,
      DEMO_IDS.careFixtureWeightEntry,
      facts,
    );

    expect(result.maturity).toBe('established');
    expect(result.reasonCodes).toContain('established');
    expect(facts.completedEvidence).toHaveLength(4);
  });
});
