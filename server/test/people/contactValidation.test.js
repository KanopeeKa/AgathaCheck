import { describe, it, expect } from '@jest/globals';

import { validateContactInput } from '../../lib/people/contactValidation.js';

describe('validateContactInput', () => {
  it('rejects invalid email', () => {
    expect(validateContactInput({ email: 'not-an-email' }).error).toBe('Invalid email');
  });

  it('allows clearing email with empty string', () => {
    expect(validateContactInput({ email: '' }).error).toBeUndefined();
  });
});
