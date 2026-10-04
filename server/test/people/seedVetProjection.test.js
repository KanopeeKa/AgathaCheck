import { readFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import { describe, expect, it } from '@jest/globals';

const healthCareSeed = readFileSync(
  path.resolve(
    path.dirname(fileURLToPath(import.meta.url)),
    '../../db/seeds/scenarios/health-care.js',
  ),
  'utf8',
);

describe('health-care seed vet projection wiring', () => {
  it('links buddy pet via relationships service and projects vet contacts', () => {
    expect(healthCareSeed).toMatch(/setPrimaryVetFromLegacyVetId/);
    expect(healthCareSeed).toMatch(/projectContact/);
    expect(healthCareSeed).toMatch(/seedPeopleVetClinicAndPerson/);
  });
});
