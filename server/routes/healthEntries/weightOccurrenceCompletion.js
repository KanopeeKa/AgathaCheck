import { v4 as uuidv4 } from 'uuid';

import { dateToIsoDate, normalizeCalendarDateInput, todayCalendarIso } from '../../lib/calendarDate.js';
import { parseWeightInput } from '../../lib/care/observations/weightUnits.js';
import { validateMeasurementSource } from '../careIntelligence/provenance.js';

export const WEIGHT_GENERIC_COMPLETE_ERROR =
  'Weight monitoring occurrences require a weight observation to complete';

export function isWeightMonitoringEntry(entry) {
  return entry?.care_family === 'weight_monitoring';
}

export function parseWeightObservationBody(body = {}) {
  const parsed = parseWeightInput({ weight: body.weight, unit: body.unit });
  if (parsed.error) {
    return { error: parsed.error };
  }
  const dateVal = normalizeCalendarDateInput(body.date || body.measured_at)
    || todayCalendarIso();
  const sourceInput = body.measurement_source ?? body.measurementSource;
  const sourceResult = validateMeasurementSource(sourceInput);
  if (!sourceResult.ok) {
    return { error: sourceResult.error };
  }
  return {
    value: {
      weight: parsed.kg,
      unit: 'kg',
      date: dateVal,
      measurement_source: sourceResult.value,
      notes: String(body.notes || '').trim(),
    },
  };
}

export function weightPayloadsSemanticallyEqual(a, b) {
  if (!a || !b) return false;
  const dateA = dateToIsoDate(a.date) || String(a.date || '');
  const dateB = dateToIsoDate(b.date) || String(b.date || '');
  return (
    Number(a.weight) === Number(b.weight)
    && String(a.unit || 'kg') === String(b.unit || 'kg')
    && dateA === dateB
    && String(a.measurement_source || 'guardian') === String(b.measurement_source || 'guardian')
    && String(a.notes || '').trim() === String(b.notes || '').trim()
  );
}

export function weightEntryToCompletionMap(row) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    weight: row.weight,
    unit: row.unit || 'kg',
    date: row.date ? dateToIsoDate(row.date) : null,
    notes: row.notes || '',
    measurement_source: row.measurement_source || 'guardian',
    health_occurrence_id: row.health_occurrence_id || null,
    created_at: row.created_at ? row.created_at.toISOString?.() || String(row.created_at) : null,
  };
}

export function newWeightEntryId() {
  return uuidv4();
}
