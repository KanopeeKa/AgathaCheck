import { describe, expect, it } from '@jest/globals';

import {
  resolveUndoAuditOccurrenceId,
} from '../../routes/healthEntries/occurrenceUndoAudit.js';

describe('resolveUndoAuditOccurrenceId', () => {
  it('uses the occurrence id returned by undoCommand', () => {
    const resolved = resolveUndoAuditOccurrenceId('actual-occ', {
      occurrence: { id: 'actual-occ' },
    });
    expect(resolved).toEqual({ ok: true, occurrenceId: 'actual-occ' });
  });

  it('rejects when undo result occurrence id does not match the URL', () => {
    const resolved = resolveUndoAuditOccurrenceId('url-occ', {
      occurrence: { id: 'other-occ' },
    });
    expect(resolved.ok).toBe(false);
    expect(resolved.status).toBe(409);
    expect(resolved.code).toBe('occurrence_mismatch');
  });

  it('falls back to URL id when undo did not return an occurrence row', () => {
    const resolved = resolveUndoAuditOccurrenceId('url-occ', { occurrence: null });
    expect(resolved).toEqual({ ok: true, occurrenceId: 'url-occ' });
  });
});
