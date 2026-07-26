import {
  buildCapacityReadModel,
  effectiveCompetencies,
  loadProfileRowsByParentId,
  loadProfileRowsByUserId,
  loadSessionUsageByFosterUser,
  parseSpeciesCapacities,
} from './fosterCapacity.js';
import {
  activitySummaryForFoster,
  loadActivityCountsByFosterUser,
  loadActivityCountsByParentId,
} from './fosteringActivitySummary.js';
import { visibilityFieldsFromRow } from './fosterVisibility.js';
import { normaliseRole } from './orgRoles.js';

const MEMBER_APPROVAL_STATE = 'approved';
const MEMBER_CREATION_SOURCE = 'member';

export function fosterParentToMap(row, {
  kind = row.kind,
  profileRow = null,
  activityCounts = null,
  capacityUsage = null,
} = {}) {
  const displayName = (row.display_name || '').trim();
  let activePets = row.active_pets || [];
  if (typeof activePets === 'string') {
    try {
      activePets = JSON.parse(activePets);
    } catch (_) {
      activePets = [];
    }
  }
  const isMember = kind === 'member';
  const speciesCapacities = parseSpeciesCapacities(
    profileRow?.species_capacities || row.species_capacities,
  );
  const capacity = buildCapacityReadModel({
    speciesCapacities,
    usageBySpecies: capacityUsage || {},
  });
  return {
    id: row.id,
    kind,
    foster_profile_id: row.foster_profile_id || null,
    user_id: row.user_id || null,
    display_name: displayName || row.email || '',
    email: row.email || null,
    phone: row.phone || null,
    foster_address: row.foster_address || '',
    notes: row.notes || '',
    role: row.role ? normaliseRole(row.role) : null,
    photo_url: row.photo_url || null,
    active_pet_count: parseInt(row.active_pet_count, 10) || 0,
    active_pets: activePets,
    approval_state: isMember
      ? MEMBER_APPROVAL_STATE
      : (row.approval_state || 'approved'),
    creation_source: isMember
      ? MEMBER_CREATION_SOURCE
      : (row.creation_source || 'manual_shelter_entry'),
    opt_out_at: row.opt_out_at || null,
    retention_category: row.retention_category || 'shelter_foster_relationship',
    species_capacities: speciesCapacities,
    self_declared_competencies: profileRow?.self_declared_competencies
      || row.self_declared_competencies
      || [],
    confirmed_competencies: profileRow?.confirmed_competencies
      || row.confirmed_competencies
      || [],
    effective_competencies: effectiveCompetencies(profileRow || row),
    available_capacity: capacity,
    fostering_activity_summary: activitySummaryForFoster(activityCounts || {}),
    ...visibilityFieldsFromRow({
      ...row,
      ...(profileRow || {}),
    }),
  };
}

export async function loadFosterParentListContext(pool, orgId) {
  const [
    activityByUser,
    activityByParent,
    usageByUser,
    profilesByUser,
    profilesByParent,
  ] = await Promise.all([
    loadActivityCountsByFosterUser(pool, orgId),
    loadActivityCountsByParentId(pool, orgId),
    loadSessionUsageByFosterUser(pool, orgId),
    loadProfileRowsByUserId(pool, orgId),
    loadProfileRowsByParentId(pool, orgId),
  ]);

  return {
    activityByUser,
    activityByParent,
    usageByUser,
    profilesByUser,
    profilesByParent,
  };
}
