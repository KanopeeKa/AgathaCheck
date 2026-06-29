/**
 * Shared mock handlers for pet access SQL used after collaborator-access changes.
 * Import and call early in test pool.query handlers (before generic fallthrough).
 */
export function handlePetAccessQuery(sql, params, {
  userId,
  ownedPetIds = ['pet-1', '123e4567-e89b-12d3-a456-426614174000'],
  deniedPetIds = ['pet-notmine', 'empty-pet'],
} = {}) {
  if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2 LIMIT 1')) {
    const [petId, uid] = params;
    if (uid !== userId || deniedPetIds.includes(petId)) return { rows: [] };
    if (ownedPetIds.includes(petId)) return { rows: [{ '?column?': 1 }] };
    return { rows: [] };
  }

  if (sql.startsWith('SELECT 1 FROM pet_access')) {
    return { rows: [] };
  }

  return null;
}

export function handleManageEntryQuery(sql, params, {
  deniedEntryIds = ['he-notmine', 'hi-notmine', 'nonexistent'],
  tableName,
} = {}) {
  const pattern = `SELECT 1 FROM ${tableName}`;
  if (sql.includes(pattern) && sql.includes('JOIN pets p')) {
    const [entryId] = params;
    if (deniedEntryIds.includes(entryId)) return { rows: [] };
    return { rows: [{ '?column?': 1 }] };
  }
  return null;
}
