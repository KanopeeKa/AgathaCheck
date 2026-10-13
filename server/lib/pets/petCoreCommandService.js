/**
 * Pet create/update/delete use cases for core profile routes (not lifecycle bulk delete).
 */

import { v4 as uuidv4 } from 'uuid';
import { normalizeCalendarDateInput } from '../calendarDate.js';
import {
  normalizeGender,
  normalizeSpecies,
  sanitizePhotoPathForWrite,
} from '../petProfileNormalize.js';
import { withTransaction } from '../db/withTransaction.js';
import {
  parseHomeTimezoneBody,
  resolveDefaultHomeTimezoneForCreate,
  normalizePetHomeTimezone,
} from '../petHomeTimezone.js';
import { logAuditEventSafe } from '../audit.js';
import { setPrimaryVetFromLegacyVetId } from '../people/relationships.js';
import { deletePet } from '../petDataLifecycle.js';
import { recordPetActivityForPet } from '../petActivity.js';
import { hasPetCapability, PET_CAPABILITIES } from '../petCapabilityPolicy.js';
import { userOwnsPet } from '../petAccess.js';
import {
  validateManagementContext,
  validateReferenceAuthority,
} from '../careIntelligence/provenance.js';
import { petRowToMap, userInOrg } from './petPresentation.js';
import { applyPetWeightFromPayload, rejectInvalidPetWeight } from './petWeightWriteHelpers.js';
import {
  mergeProfileFactsFromBody,
  normaliseProfileFacts,
  profileFactDefaultsForCreate,
} from './profileFacts.js';

export { rejectInvalidPetWeight };

export async function createPet(pool, userId, body, req) {
  const id = body.id || uuidv4();
  const {
    name, breed = '', age, weight,
    bio = '', insurance = '',
    vetId, colorValue, passedAway = false,
    organization_id,
  } = body;
  const factDefaults = profileFactDefaultsForCreate(body);
  if (!factDefaults.ok) {
    return { error: factDefaults.error, status: 400 };
  }
  const {
    identification_status,
    neuter_status,
    identification_status_source,
    neuter_status_source,
    identification_status_updated_at,
    neuter_status_updated_at,
    chip_id: factChipId,
    chip_dismissed: factChipDismissed,
    neuter_dismissed: factNeuterDismissed,
  } = factDefaults.patch;
  const chipId = factChipId;
  const species = normalizeSpecies(body.species);
  const gender = normalizeGender(body.gender);
  const photoSanitized = sanitizePhotoPathForWrite(body.photoPath);
  if (!photoSanitized.ok) {
    return { error: photoSanitized.error, status: 400 };
  }
  const photoPath = photoSanitized.value;
  const dateOfBirth = normalizeCalendarDateInput(body.dateOfBirth || body.date_of_birth);
  const neuteredDate = normalizeCalendarDateInput(body.neuteredDate);
  if (organization_id && !(await userInOrg(pool, organization_id, userId))) {
    return { error: 'Not a member of this organization', status: 403 };
  }
  const homeTimezone = resolveDefaultHomeTimezoneForCreate(req);
  const syncedPet = await withTransaction(pool, async (db) => {
    const result = await db.query(
      `INSERT INTO pets (id, user_id, name, species, breed, age, date_of_birth, weight, gender,
        bio, insurance, neutered_date, neuter_dismissed, chip_id, chip_dismissed,
        identification_status, neuter_status,
        identification_status_source, neuter_status_source,
        identification_status_updated_at, neuter_status_updated_at,
        photo_path, vet_id, color_index, passed_away, organization_id, home_timezone)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27)
       ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, species = EXCLUDED.species, breed = EXCLUDED.breed,
        age = EXCLUDED.age, date_of_birth = EXCLUDED.date_of_birth, gender = EXCLUDED.gender,
        bio = EXCLUDED.bio, insurance = EXCLUDED.insurance, neutered_date = EXCLUDED.neutered_date,
        neuter_dismissed = EXCLUDED.neuter_dismissed, chip_id = EXCLUDED.chip_id, chip_dismissed = EXCLUDED.chip_dismissed,
        identification_status = EXCLUDED.identification_status, neuter_status = EXCLUDED.neuter_status,
        identification_status_source = EXCLUDED.identification_status_source,
        neuter_status_source = EXCLUDED.neuter_status_source,
        identification_status_updated_at = EXCLUDED.identification_status_updated_at,
        neuter_status_updated_at = EXCLUDED.neuter_status_updated_at,
        photo_path = EXCLUDED.photo_path, vet_id = EXCLUDED.vet_id, color_index = EXCLUDED.color_index,
        passed_away = EXCLUDED.passed_away, organization_id = EXCLUDED.organization_id,
        home_timezone = EXCLUDED.home_timezone, updated_at = NOW()
       WHERE pets.user_id = $2 RETURNING *`,
      [id, userId, name, species, breed, age, dateOfBirth, null, gender,
        bio, insurance, neuteredDate, factNeuterDismissed, chipId, factChipDismissed,
        identification_status, neuter_status,
        identification_status_source, neuter_status_source,
        identification_status_updated_at, neuter_status_updated_at,
        photoPath, vetId || null, colorValue != null ? colorValue : null,
        passedAway, organization_id || null, homeTimezone],
    );
    const pet = result.rows[0];
    await applyPetWeightFromPayload(db, {
      petId: pet.id,
      userId,
      weight,
      body,
      req,
    });
    const refreshed = await db.query('SELECT * FROM pets WHERE id = $1', [pet.id]);
    return refreshed.rows[0] || pet;
  });
  await setPrimaryVetFromLegacyVetId(pool, syncedPet.id, syncedPet.vet_id, userId);
  logAuditEventSafe(pool, {
    actorUserId: userId,
    action: 'pet.created',
    resourceType: 'pet',
    resourceId: syncedPet.id,
    petId: syncedPet.id,
    orgId: syncedPet.organization_id || null,
    metadata: { species: syncedPet.species },
    req,
  });
  return { pet: petRowToMap(syncedPet), status: 201 };
}

export async function updatePet(pool, userId, petId, body, req) {
  const canEdit = await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.PROFILE_EDIT);
  if (!canEdit) {
    const canView = await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.VIEW);
    if (canView) {
      return { error: 'Forbidden', status: 403 };
    }
    return { error: 'Pet not found', status: 404 };
  }
  const {
    name, breed = '', age, weight,
    bio = '', insurance = '',
    vetId, colorValue, passedAway = false,
    organization_id,
  } = body;
  const species = normalizeSpecies(body.species);
  const gender = normalizeGender(body.gender);
  const existingPet = await pool.query(
    'SELECT * FROM pets WHERE id = $1',
    [petId],
  );
  let photoPath = existingPet.rows[0]?.photo_path ?? null;
  if (Object.prototype.hasOwnProperty.call(body, 'photoPath')) {
    const photoSanitized = sanitizePhotoPathForWrite(body.photoPath);
    if (!photoSanitized.ok) {
      return { error: photoSanitized.error, status: 400 };
    }
    photoPath = photoSanitized.value;
  }
  const dateOfBirth = normalizeCalendarDateInput(body.dateOfBirth || body.date_of_birth);
  const neuteredDate = normalizeCalendarDateInput(body.neuteredDate);
  const previousOrgId = existingPet.rows[0]?.organization_id || null;
  const nextOrgId = organization_id || null;
  if (nextOrgId && String(nextOrgId) !== String(previousOrgId || '')
      && !(await userInOrg(pool, nextOrgId, userId))) {
    return { error: 'Not a member of this organization', status: 403 };
  }
  const existingRow = existingPet.rows[0] || {};
  let weightReferenceValue = existingRow.weight_reference_value ?? null;
  let weightReferenceAuthority = existingRow.weight_reference_authority ?? null;
  let weightManagementContext = existingRow.weight_management_context || 'none';
  if (Object.prototype.hasOwnProperty.call(body, 'weight_reference_value')
      || Object.prototype.hasOwnProperty.call(body, 'weightReferenceValue')) {
    const rawRef = Object.prototype.hasOwnProperty.call(body, 'weight_reference_value')
      ? body.weight_reference_value
      : body.weightReferenceValue;
    if (rawRef === null || rawRef === '') {
      weightReferenceValue = null;
    } else {
      const parsed = typeof rawRef === 'number' ? rawRef : parseFloat(String(rawRef));
      if (!Number.isFinite(parsed) || parsed <= 0) {
        return { error: 'weight_reference_value must be a positive number', status: 400 };
      }
      weightReferenceValue = parsed;
    }
  }
  if (Object.prototype.hasOwnProperty.call(body, 'weight_reference_authority')
      || Object.prototype.hasOwnProperty.call(body, 'weightReferenceAuthority')) {
    const authResult = validateReferenceAuthority(
      body.weight_reference_authority ?? body.weightReferenceAuthority,
    );
    if (!authResult.ok) return { error: authResult.error, status: 400 };
    weightReferenceAuthority = authResult.value;
  }
  if (Object.prototype.hasOwnProperty.call(body, 'weight_management_context')
      || Object.prototype.hasOwnProperty.call(body, 'weightManagementContext')) {
    const ctxResult = validateManagementContext(
      body.weight_management_context ?? body.weightManagementContext,
    );
    if (!ctxResult.ok) return { error: ctxResult.error, status: 400 };
    weightManagementContext = ctxResult.value;
  }
  const homeTimezoneParsed = parseHomeTimezoneBody(body);
  const homeTimezone = homeTimezoneParsed
    ?? normalizePetHomeTimezone(existingRow.home_timezone);
  const mergedFacts = mergeProfileFactsFromBody(body, existingRow);
  if (!mergedFacts.ok) {
    return { error: mergedFacts.error, status: 400 };
  }
  const normalised = normaliseProfileFacts(mergedFacts.patch, neuteredDate);
  if (!normalised.ok) {
    return { error: normalised.error, status: 400 };
  }
  const {
    chip_id: chipId,
    chip_dismissed: chipDismissed,
    neuter_dismissed: neuterDismissed,
    identification_status,
    neuter_status,
    identification_status_source,
    neuter_status_source,
    identification_status_updated_at,
    neuter_status_updated_at,
  } = normalised.patch;
  const syncedPet = await withTransaction(pool, async (db) => {
    const result = await db.query(
      `UPDATE pets SET name=$1, species=$2, breed=$3, age=$4, date_of_birth=$5, gender=$6,
        bio=$7, insurance=$8, neutered_date=$9, neuter_dismissed=$10, chip_id=$11, chip_dismissed=$12,
        identification_status=$13, neuter_status=$14,
        identification_status_source=$15, neuter_status_source=$16,
        identification_status_updated_at=$17, neuter_status_updated_at=$18,
        photo_path=$19, vet_id=$20, color_index=$21, passed_away=$22, organization_id=$23,
        weight_reference_value=$24, weight_reference_authority=$25, weight_management_context=$26,
        home_timezone=$27, updated_at=NOW()
       WHERE id=$28 RETURNING *`,
      [name, species, breed, age, dateOfBirth, gender,
        bio, insurance, neuteredDate, neuterDismissed, chipId, chipDismissed,
        identification_status, neuter_status,
        identification_status_source, neuter_status_source,
        identification_status_updated_at, neuter_status_updated_at,
        photoPath, vetId || null, colorValue != null ? colorValue : null,
        passedAway, organization_id || null,
        weightReferenceValue, weightReferenceAuthority, weightManagementContext,
        homeTimezone, petId],
    );
    if (result.rows.length === 0) {
      return null;
    }
    const pet = result.rows[0];
    await applyPetWeightFromPayload(db, {
      petId,
      userId,
      weight,
      body,
      req,
    });
    const refreshed = await db.query('SELECT * FROM pets WHERE id = $1', [petId]);
    return refreshed.rows[0] || pet;
  });
  if (!syncedPet) {
    return { error: 'Pet not found', status: 404 };
  }
  if (
    Object.prototype.hasOwnProperty.call(body, 'vetId')
    || Object.prototype.hasOwnProperty.call(body, 'vet_id')
  ) {
    const resolvedVetId = vetId ?? body.vet_id ?? null;
    await setPrimaryVetFromLegacyVetId(pool, petId, resolvedVetId, userId);
  }
  logAuditEventSafe(pool, {
    actorUserId: userId,
    action: 'pet.updated',
    resourceType: 'pet',
    resourceId: petId,
    petId,
    orgId: syncedPet.organization_id || null,
    req,
  });
  if (syncedPet.organization_id) {
    recordPetActivityForPet(pool, {
      petId,
      actorUserId: userId,
      eventType: 'profile_edit',
      metadata: { field_count: Object.keys(body || {}).length },
    });
  }
  return { pet: petRowToMap(syncedPet) };
}

export async function deleteOwnedPet(pool, userId, petId, req) {
  if (!(await userOwnsPet(pool, petId, userId))) {
    return { error: 'Pet not found', status: 404 };
  }
  const result = await deletePet(pool, petId, { actorUserId: userId, req });
  return { result };
}
