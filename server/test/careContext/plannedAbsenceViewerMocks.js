/**
 * Mock pool handlers for loadAbsenceForViewer (phase 2 visibility reads).
 */

export function mockViewerAbsenceLoad(sql, absenceRow) {
  if (sql.includes('SELECT * FROM planned_absences WHERE id = $1') && !sql.includes('user_id = $2')) {
    return { rows: absenceRow ? [absenceRow] : [] };
  }
  return null;
}

/** Declarer owns every pet on the absence (typical unit-test default). */
export function mockViewerFullAccessOnPets(sql, params, userId, petIds) {
  const ids = Array.isArray(petIds) ? petIds : [petIds];
  if (sql.includes('FROM pets WHERE id = $1 AND user_id = $2')) {
    const [pet, owner] = params;
    if (owner === userId && ids.includes(pet)) {
      return { rows: [{ id: pet }] };
    }
    return { rows: [] };
  }
  if (sql.includes('FROM pet_access') && sql.includes('role = $3')) {
    const [p, u, role] = params;
    if (u === userId && ids.includes(p) && role === 'co_parent') {
      return { rows: [{ role: 'co_parent' }] };
    }
    return { rows: [] };
  }
  if (sql.includes('FROM pet_access')) {
    return { rows: [] };
  }
  if (sql.includes('household_pets')) {
    return { rows: [] };
  }
  return null;
}
