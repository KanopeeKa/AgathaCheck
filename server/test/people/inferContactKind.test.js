import { describe, it, expect } from '@jest/globals';

import { inferContactKind } from '../../lib/people/inferContactKind.js';

describe('inferContactKind', () => {
  it('infers organisation from name keywords', () => {
    expect(inferContactKind({ name: 'Greenhill Veterinary Clinic', roles: ['vet'] }))
      .toBe('organisation');
  });

  it('infers person for sitter role', () => {
    expect(inferContactKind({ name: 'Jamie Taylor', roles: ['sitter'] }))
      .toBe('person');
  });
});
