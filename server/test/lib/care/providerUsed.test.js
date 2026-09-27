import { describe, expect, it } from '@jest/globals';

import { parseEntryProviderInput } from '../../../routes/healthEntries/shared.js';

describe('parseEntryProviderInput', () => {
  it('rejects contact and typed name together', () => {
    const result = parseEntryProviderInput({
      provider_contact_id: 'c-1',
      provider_typed_name: 'Dr Smith',
    });
    expect(result.error).toMatch(/not both/);
  });

  it('accepts typed name only', () => {
    const result = parseEntryProviderInput({ provider_typed_name: '  Mobile vet  ' });
    expect(result.typedName).toBe('Mobile vet');
    expect(result.contactId).toBeUndefined();
  });
});
