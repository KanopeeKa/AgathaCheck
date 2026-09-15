import { describe, expect, it } from '@jest/globals';

import {
  defaultRecurrenceAnchorForCareFamily,
  resolveRecurrenceAnchorForWrite,
} from '../../lib/care/schedule/recurrenceAnchorDefaults.js';

describe('recurrenceAnchorDefaults', () => {
  it('defaults vaccination and parasite_prevention to from_due_date', () => {
    expect(defaultRecurrenceAnchorForCareFamily('vaccination')).toBe('from_due_date');
    expect(defaultRecurrenceAnchorForCareFamily('parasite_prevention')).toBe('from_due_date');
  });

  it('defaults other care families to from_completion', () => {
    expect(defaultRecurrenceAnchorForCareFamily('medication')).toBe('from_completion');
    expect(defaultRecurrenceAnchorForCareFamily('weight_monitoring')).toBe('from_completion');
    expect(defaultRecurrenceAnchorForCareFamily('grooming')).toBe('from_completion');
    expect(defaultRecurrenceAnchorForCareFamily(null)).toBe('from_completion');
  });

  it('honours explicit anchor over family default', () => {
    expect(resolveRecurrenceAnchorForWrite({
      careFamily: 'vaccination',
      explicitAnchor: 'from_completion',
    })).toBe('from_completion');
    expect(resolveRecurrenceAnchorForWrite({
      careFamily: 'medication',
      explicitAnchor: 'from_due_date',
    })).toBe('from_due_date');
  });

  it('applies family default when anchor omitted', () => {
    expect(resolveRecurrenceAnchorForWrite({
      careFamily: 'parasite_prevention',
      explicitAnchor: null,
    })).toBe('from_due_date');
    expect(resolveRecurrenceAnchorForWrite({
      careFamily: 'medication',
      explicitAnchor: undefined,
    })).toBe('from_completion');
  });

  it('rejects invalid explicit anchors', () => {
    expect(() => resolveRecurrenceAnchorForWrite({
      careFamily: 'medication',
      explicitAnchor: 'from_moon',
    })).toThrow(/invalid recurrence anchor/i);
  });
});
