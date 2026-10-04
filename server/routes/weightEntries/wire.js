import { dateToIsoDate } from '../../lib/calendarDate.js';

export function weightEntryToMap(row) {
  const fulfils = row.fulfils_entry_id
    ? {
      entry_id: row.fulfils_entry_id,
      entry_name: row.fulfils_entry_name,
      occurrence_id: row.fulfils_occurrence_id,
      scheduled_date: row.fulfils_scheduled_date
        ? dateToIsoDate(row.fulfils_scheduled_date)
        : null,
    }
    : null;
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
    fulfils,
    created_at: row.created_at ? row.created_at.toISOString?.() || String(row.created_at) : null,
  };
}

export function fulfilmentToMap(fulfilment) {
  return fulfilment;
}
