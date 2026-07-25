import { dateToIsoDate, normalizeCalendarDateInput } from './calendarDate.js';
import {
  buildCapacityReadModel,
  effectiveCompetencies,
  fosterHasCapacityForSpecies,
  fosterMatchesCompetencyFilter,
  loadProfileRowsByParentId,
  loadSessionUsageByFosterUser,
  parseSpeciesCapacities,
} from './fosterCapacity.js';

export const FOSTER_REQUEST_STATUSES = new Set(['draft', 'sent', 'cancelled']);
export const FOSTER_RESPONSE_TYPES = new Set(['can_help', 'cannot_help', 'pending']);

export function requestToMap(row, {
  pets = [],
  targets = [],
  responses = [],
} = {}) {
  const responseSummary = { pending: 0, can_help: 0, cannot_help: 0 };
  if (responses.length > 0) {
    for (const item of responses) {
      const key = item.response || 'pending';
      if (responseSummary[key] !== undefined) {
        responseSummary[key] += 1;
      }
    }
  } else {
    responseSummary.pending = parseInt(row.pending_count, 10) || 0;
    responseSummary.can_help = parseInt(row.can_help_count, 10) || 0;
    responseSummary.cannot_help = parseInt(row.cannot_help_count, 10) || 0;
  }

  return {
    id: row.id,
    organization_id: row.organization_id,
    message: row.message || '',
    status: row.status,
    created_by: row.created_by || null,
    sent_at: row.sent_at || null,
    created_at: row.created_at,
    updated_at: row.updated_at,
    pet_ids: pets.length > 0
      ? pets.map((pet) => pet.pet_id)
      : (row.pet_ids || []),
    pets,
    targets,
    responses,
    target_count: targets.length > 0
      ? targets.length
      : (parseInt(row.target_count, 10) || 0),
    response_summary: responseSummary,
  };
}

export function petRowToMap(row) {
  return {
    pet_id: row.pet_id,
    pet_name: row.pet_name || '',
    species: row.species || null,
  };
}

export function targetRowToMap(row) {
  return {
    org_foster_parent_id: row.org_foster_parent_id,
    display_name: row.display_name || '',
    email: row.email || null,
    user_id: row.user_id || null,
    approval_state: row.approval_state || null,
    opt_out_at: row.opt_out_at || null,
  };
}

export function responseRowToMap(row) {
  return {
    id: row.id,
    org_foster_parent_id: row.org_foster_parent_id,
    response: row.response,
    message: row.message || '',
    earliest_availability: dateToIsoDate(row.earliest_availability),
    capacity_confirmed_at: row.capacity_confirmed_at || null,
    responded_at: row.responded_at || null,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export function validateCreatePayload(data) {
  const message = (data.message || '').trim();
  const petIds = Array.isArray(data.pet_ids || data.petIds)
    ? (data.pet_ids || data.petIds).map((id) => String(id).trim()).filter(Boolean)
    : [];
  const targetIds = Array.isArray(data.org_foster_parent_ids || data.orgFosterParentIds)
    ? (data.org_foster_parent_ids || data.orgFosterParentIds).map((id) => String(id).trim()).filter(Boolean)
    : [];
  const sendNow = data.send === true
    || data.send_now === true
    || data.sendNow === true
    || (data.status || '').trim() === 'sent';

  if (!message) {
    return { error: 'Message is required' };
  }
  if (petIds.length === 0) {
    return { error: 'At least one pet is required' };
  }
  if (targetIds.length === 0) {
    return { error: 'At least one foster parent target is required' };
  }

  return {
    message,
    petIds,
    targetIds,
    sendNow,
  };
}

export function validateResponsePayload(data) {
  const response = (data.response || '').trim();
  if (!FOSTER_RESPONSE_TYPES.has(response) || response === 'pending') {
    return { error: 'Invalid response' };
  }

  const message = (data.message || '').trim();
  const earliestAvailability = normalizeCalendarDateInput(
    data.earliest_availability || data.earliestAvailability,
  );

  if (response === 'can_help' && !earliestAvailability) {
    return { error: 'earliest_availability is required when response is can_help' };
  }

  return {
    response,
    message,
    earliestAvailability: response === 'can_help' ? earliestAvailability : null,
  };
}

export async function loadEligibleTargets(client, orgId, targetIds) {
  const result = await client.query(
    `SELECT fp.id AS org_foster_parent_id,
            fp.display_name,
            fp.email,
            fp.user_id,
            fp.approval_state,
            fp.opt_out_at
     FROM org_foster_parents fp
     WHERE fp.organization_id = $1
       AND fp.id = ANY($2::uuid[])
       AND fp.approval_state = 'approved'
       AND fp.opt_out_at IS NULL`,
    [orgId, targetIds],
  );
  return result.rows;
}

export async function assertPetsInOrg(client, orgId, petIds) {
  const result = await client.query(
    `SELECT id
     FROM pets
     WHERE organization_id = $1
       AND id = ANY($2::uuid[])
       AND COALESCE(passed_away, false) = false`,
    [orgId, petIds],
  );
  return result.rows.map((row) => row.id);
}

export async function loadRequestPets(client, requestId) {
  const result = await client.query(
    `SELECT frp.pet_id, p.name AS pet_name, p.species
     FROM foster_request_pets frp
     JOIN pets p ON p.id = frp.pet_id
     WHERE frp.foster_request_id = $1
     ORDER BY p.name`,
    [requestId],
  );
  return result.rows.map(petRowToMap);
}

export async function loadRequestTargets(client, requestId) {
  const result = await client.query(
    `SELECT frt.org_foster_parent_id,
            fp.display_name,
            fp.email,
            fp.user_id,
            fp.approval_state,
            fp.opt_out_at
     FROM foster_request_targets frt
     JOIN org_foster_parents fp ON fp.id = frt.org_foster_parent_id
     WHERE frt.foster_request_id = $1
     ORDER BY fp.display_name`,
    [requestId],
  );
  return result.rows.map(targetRowToMap);
}

export async function loadRequestResponses(client, requestId) {
  const result = await client.query(
    `SELECT *
     FROM foster_request_responses
     WHERE foster_request_id = $1
     ORDER BY created_at`,
    [requestId],
  );
  return result.rows.map(responseRowToMap);
}

export async function loadRequestDetail(client, requestId, orgId) {
  const result = await client.query(
    `SELECT *
     FROM foster_requests
     WHERE id = $1 AND organization_id = $2`,
    [requestId, orgId],
  );
  if (!result.rows.length) return null;

  const row = result.rows[0];
  const [pets, targets, responses] = await Promise.all([
    loadRequestPets(client, requestId),
    loadRequestTargets(client, requestId),
    loadRequestResponses(client, requestId),
  ]);

  return requestToMap(row, { pets, targets, responses });
}

export async function loadEligibleFosterTargetsWithCapacity(pool, orgId, {
  petIds = [],
  species = null,
  requiredCompetencies = [],
} = {}) {
  const petsResult = await pool.query(
    `SELECT id, species
     FROM pets
     WHERE organization_id = $1
       AND id = ANY($2::uuid[])`,
    [orgId, petIds],
  );
  const targetSpecies = species
    ? [species]
    : [...new Set(petsResult.rows.map((row) => row.species).filter(Boolean))];

  const parentsResult = await pool.query(
    `SELECT fp.id AS org_foster_parent_id,
            fp.display_name,
            fp.email,
            fp.user_id,
            fp.approval_state,
            fp.opt_out_at,
            fp.foster_profile_id
     FROM org_foster_parents fp
     WHERE fp.organization_id = $1
       AND fp.approval_state = 'approved'
       AND fp.opt_out_at IS NULL
     ORDER BY fp.display_name`,
    [orgId],
  );

  const [profilesByParent, usageByUser] = await Promise.all([
    loadProfileRowsByParentId(pool, orgId),
    loadSessionUsageByFosterUser(pool, orgId),
  ]);

  return parentsResult.rows
    .map((row) => {
      const profileRow = profilesByParent.get(row.org_foster_parent_id) || {};
      const speciesCapacities = parseSpeciesCapacities(profileRow.species_capacities);
      const usageBySpecies = row.user_id ? (usageByUser.get(row.user_id) || {}) : {};
      const hasCapacity = targetSpecies.length === 0
        || targetSpecies.every((item) => fosterHasCapacityForSpecies({
          speciesCapacities,
          usageBySpecies,
          species: item,
        }));
      const matchesCompetency = fosterMatchesCompetencyFilter(
        profileRow,
        requiredCompetencies,
      );
      return {
        org_foster_parent_id: row.org_foster_parent_id,
        display_name: row.display_name || '',
        email: row.email || null,
        user_id: row.user_id || null,
        approval_state: row.approval_state,
        opt_out_at: row.opt_out_at || null,
        species_capacities: speciesCapacities,
        effective_competencies: effectiveCompetencies(profileRow),
        available_capacity: buildCapacityReadModel({
          speciesCapacities,
          usageBySpecies,
          species: targetSpecies[0] || null,
        }),
        eligible: hasCapacity && matchesCompetency,
        ineligible_reason: !hasCapacity
          ? 'insufficient_capacity'
          : (!matchesCompetency ? 'competency_mismatch' : null),
      };
    })
    .filter((row) => row.eligible);
}
