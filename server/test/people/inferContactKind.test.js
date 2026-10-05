import { describe, it, expect } from '@jest/globals';

import { contactGroup, inferContactKind } from '../../lib/people/inference.js';

describe('inferContactKind', () => {
  it('infers organisation from name keywords', () => {
    expect(inferContactKind({ name: 'Greenhill Veterinary Clinic', roles: ['vet'] }))
      .toBe('organisation');
  });

  it('infers person for sitter role', () => {
    expect(inferContactKind({ name: 'Jamie Taylor', roles: ['sitter'] }))
      .toBe('person');
  });

  it('derives contact group from roles', () => {
    expect(contactGroup(['sitter'], 'person')).toBe('carer');
    expect(contactGroup(['vet'], 'person')).toBe('professional');
  });
});
