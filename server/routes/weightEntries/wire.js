import { dateToIsoDate } from '../../lib/calendarDate.js';

export function weightEntryToMap(row) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    pet_name: row.pet_name || null,
    weight: row.weight,
    unit: 'kg',
    date: row.date ? dateToIsoDate(row.date) : null,
    notes: row.notes || '',
    measurement_source: row.measurement_source || 'guardian',
    health_occurrence_id: row.health_occurrence_id || null,
    created_at: row.created_at ? row.created_at.toISOString?.() || String(row.created_at) : null,
  };
}
