/**
 * "If done after the due date" (D-CSM-026 v4, D2): Keep · Skip the next date
 * · Move this and following, or unset (Keep). No "Ask me".
 */
import { updateEntryFields } from '../../lib/care/occurrence/entryRepository.js';

export const LATE_COMPLETION_CHOICES = ['keep', 'skip_next', 'shift_following'];

/**
 * @param {object} data request body
 * @returns {{ present: boolean, value?: string|null, error?: string }}
 */
export function parseLateCompletionChoice(data = {}) {
  const key = ['late_completion_choice', 'lateCompletionChoice'].find((k) => k in data);
  if (!key) return { present: false };
  const raw = data[key];
  if (raw === null || raw === '') return { present: true, value: null };
  if (!LATE_COMPLETION_CHOICES.includes(raw)) {
    return { present: false, error: `late_completion_choice must be one of ${LATE_COMPLETION_CHOICES.join(', ')}` };
  }
  return { present: true, value: raw };
}

/**
 * Apply a parsed choice inside the command transaction.
 *
 * @param {import('pg').PoolClient} db
 * @param {object} row health_entries row
 * @param {{ present: boolean, value?: string|null }} choice
 */
export async function applyLateCompletionChoice(db, row, choice) {
  if (!choice.present) return row;
  return updateEntryFields(db, row.id, { late_completion_choice: choice.value });
}
