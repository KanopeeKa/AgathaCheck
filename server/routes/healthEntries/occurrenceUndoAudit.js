/**
 * Audit metadata for per-occurrence undo — URL id must match undoCommand result.
 *
 * @param {string} urlOccId
 * @param {{ occurrence?: { id?: string }|null, undoneType?: string }} out
 */
export function resolveUndoAuditOccurrenceId(urlOccId, out) {
  const actualId = out?.occurrence?.id ?? null;
  if (actualId && urlOccId && actualId !== urlOccId) {
    return { ok: false, status: 409, code: 'occurrence_mismatch' };
  }
  return { ok: true, occurrenceId: actualId ?? urlOccId };
}
