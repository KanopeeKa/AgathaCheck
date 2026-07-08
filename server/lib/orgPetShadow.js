import { v4 as uuidv4 } from 'uuid';

import { dateToIsoDate } from './calendarDate.js';

/**
 * Build a frozen point-in-time snapshot for org shadow records.
 */
export async function buildPetShadowSnapshot(db, petId) {
  const petResult = await db.query('SELECT * FROM pets WHERE id = $1', [petId]);
  if (petResult.rows.length === 0) return null;
  const pet = petResult.rows[0];

  const [health, weight, vets] = await Promise.all([
    db.query(
      'SELECT id, type, name, dosage, frequency, start_date, next_due_date, notes, status FROM health_entries WHERE pet_id = $1 ORDER BY created_at',
      [petId],
    ),
    db.query(
      'SELECT id, weight, unit, date, notes, measured_at FROM weight_entries WHERE pet_id = $1 ORDER BY measured_at',
      [petId],
    ),
    pet.vet_id
      ? db.query('SELECT id, name, clinic, phone, email FROM vets WHERE id = $1', [pet.vet_id])
      : Promise.resolve({ rows: [] }),
  ]);

  return {
    pet: {
      id: pet.id,
      name: pet.name,
      species: pet.species,
      breed: pet.breed || '',
      date_of_birth: pet.date_of_birth ? dateToIsoDate(pet.date_of_birth) : null,
      weight: pet.weight,
      gender: pet.gender,
      bio: pet.bio || '',
      insurance: pet.insurance || '',
      chip_id: pet.chip_id || '',
      photo_path: pet.photo_path,
      passed_away: pet.passed_away || false,
    },
    health_entries: health.rows.map((r) => ({
      id: r.id,
      type: r.type,
      name: r.name,
      dosage: r.dosage || '',
      frequency: r.frequency,
      start_date: r.start_date ? dateToIsoDate(r.start_date) : null,
      next_due_date: r.next_due_date ? dateToIsoDate(r.next_due_date) : null,
      notes: r.notes || '',
      status: r.status,
    })),
    weight_entries: weight.rows.map((r) => ({
      id: r.id,
      weight: r.weight,
      unit: r.unit,
      date: r.date ? dateToIsoDate(r.date) : null,
      notes: r.notes || '',
    })),
    vet: vets.rows[0] || null,
    captured_at: new Date().toISOString(),
  };
}

/**
 * Insert frozen shadow when guardianship leaves an org.
 */
export async function createOrgPetShadow(db, {
  organizationId,
  pet,
  transferType,
  transferredToUserId = null,
  transferredToOrgId = null,
  actorUserId,
  notes = '',
}) {
  const snapshot = await buildPetShadowSnapshot(db, pet.id);
  const archiveId = uuidv4();
  const now = new Date();

  await db.query(
    `INSERT INTO archived_pets (
       id, organization_id, user_id, pet_id, pet_name, species,
       transfer_type, transferred_to_user_id, transferred_to_org_id,
       notes, archived_at, created_at, shadow_snapshot, frozen_at
     ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$11,$12,$11)`,
    [
      archiveId,
      organizationId,
      actorUserId,
      pet.id,
      pet.name,
      pet.species || '',
      transferType,
      transferredToUserId,
      transferredToOrgId,
      notes || '',
      now,
      JSON.stringify(snapshot || {}),
    ],
  );

  return archiveId;
}

export async function deleteShadowForPetAndOrg(db, petId, organizationId) {
  await db.query(
    'DELETE FROM archived_pets WHERE pet_id = $1 AND organization_id = $2',
    [petId, organizationId],
  );
}
