import { describe, expect, it, jest } from '@jest/globals';

import { resolveProviderUsedForCompletion } from '../../../lib/care/providerUsed.js';
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

describe('resolveProviderUsedForCompletion', () => {
  it('uses canAttachContactToPet for body overrides', async () => {
    const attachModule = await import('../../../lib/people/access.js');
    const spy = jest.spyOn(attachModule, 'canAttachContactToPet').mockResolvedValue(true);
    const pool = {
      query: async (sql) => {
        if (sql.includes('FROM people_contacts pc')) {
          return {
            rows: [{
              id: 'override-1',
              directory_id: 'dir-1',
              kind: 'person',
              name: 'Override',
              phone: null,
              email: null,
            }],
          };
        }
        return { rows: [] };
      },
    };
    const result = await resolveProviderUsedForCompletion(
      pool,
      'user-1',
      { pet_id: 'pet-1', provider_contact_id: 'entry-contact' },
      { provider_contact_id: 'override-1' },
    );
    expect(spy).toHaveBeenCalledWith(pool, 'user-1', 'override-1', 'pet-1');
    expect(result.contactId).toBe('override-1');
    spy.mockRestore();
  });
});
