import { extractUserId } from '../../lib/requireAuth.js';
import { dateToIsoDate } from '../../lib/calendarDate.js';

export { extractUserId };
export function issueRowToMap(row) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    user_id: row.user_id,
    pet_name: row.pet_name || null,
    title: row.name || '',
    description: row.notes || '',
    name: row.name || '',
    issue_type: row.issue_type,
    notes: row.notes || '',
    start_date: row.start_date ? dateToIsoDate(row.start_date) : null,
    end_date: row.end_date ? dateToIsoDate(row.end_date) : null,
    status: row.status || 'active',
    created_at: row.created_at ? row.created_at.toISOString?.() || String(row.created_at) : null,
    updated_at: row.updated_at ? row.updated_at.toISOString?.() || String(row.updated_at) : null,
  };
}
