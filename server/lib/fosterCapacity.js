/**
 * J2 Ph3 / G0 §5.2: declared capacity minus J3 session counts.
 */
import {
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_PENDING_ACCEPTANCE,
  SESSION_STATUS_PREPARATION,
  SESSION_STATUS_READY_TO_START,
} from './fosterPlacements.js';

export const COMPETENCY_TAXONOMY = [
  'very_young',
  'elderly',
  'light_medical',
  'heavy_medical',
  'light_behavioural',
  'heavy_behavioural',
];

const PREPARATION_STATUSES = [
  SESSION_STATUS_PENDING_ACCEPTANCE,
  SESSION_STATUS_PREPARATION,
  SESSION_STATUS_READY_TO_START,
];

const ACTIVE_STATUSES = [SESSION_STATUS_ACTIVE];

export function parseJsonArray(value) {
  if (!value) return [];
  if (Array.isArray(value)) return value;
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed : [];
    } catch (_) {
      return [];
    }
  }
  return [];
}

export function parseSpeciesCapacities(raw) {
  return parseJsonArray(raw).map((entry) => ({
    species: String(entry?.species || '').trim(),
    declared: Math.max(0, parseInt(entry?.declared, 10) || 0),
  })).filter((entry) => entry.species);
}

export function effectiveCompetencies(profileRow) {
  const confirmed = parseJsonArray(profileRow?.confirmed_competencies);
  if (confirmed.length > 0) return confirmed.map(String);
  return parseJsonArray(profileRow?.self_declared_competencies).map(String);
}

export function declaredCapacityForSpecies(capacities, species) {
  const match = capacities.find((entry) => entry.species === species);
  return match?.declared ?? 0;
}

export function availableCapacity(declared, preparationCount, activeCount) {
  return Math.max(0, declared - preparationCount - activeCount);
}

export function buildCapacityReadModel({
  speciesCapacities,
  usageBySpecies = {},
  species,
}) {
  const capacities = parseSpeciesCapacities(speciesCapacities);
  const targetSpecies = species
    ? [species]
    : [...new Set(capacities.map((entry) => entry.species))];

  return targetSpecies.map((item) => {
    const declared = declaredCapacityForSpecies(capacities, item);
    const usage = usageBySpecies[item] || { preparation: 0, active: 0 };
    const available = availableCapacity(declared, usage.preparation, usage.active);
    return {
      species: item,
      declared,
      preparation_count: usage.preparation,
      active_count: usage.active,
      available,
    };
  });
}

export async function loadProfileRowsByParentId(pool, orgId) {
  const result = await pool.query(
    `SELECT fp.id AS org_foster_parent_id,
            fprof.species_capacities,
            fprof.self_declared_competencies,
            fprof.confirmed_competencies
     FROM org_foster_parents fp
     LEFT JOIN foster_profiles fprof ON fprof.id = fp.foster_profile_id
     WHERE fp.organization_id = $1`,
    [orgId],
  );
  const profiles = new Map();
  for (const row of result.rows) {
    profiles.set(row.org_foster_parent_id, row);
  }
  return profiles;
}

export async function loadProfileRowsByUserId(pool, orgId) {
  const result = await pool.query(
    `SELECT u.id AS user_id,
            fprof.species_capacities,
            fprof.self_declared_competencies,
            fprof.confirmed_competencies
     FROM organization_users ou
     JOIN users u ON u.id = ou.user_id
     LEFT JOIN foster_profiles fprof ON fprof.user_id = u.id
     WHERE ou.organization_id = $1`,
    [orgId],
  );
  const profiles = new Map();
  for (const row of result.rows) {
    profiles.set(row.user_id, row);
  }
  return profiles;
}

export async function loadSessionUsageByFosterUser(pool, orgId) {
  const result = await pool.query(
    `SELECT fp.foster_user_id,
            p.species,
            COUNT(*) FILTER (WHERE fp.status = ANY($2::text[]))::int AS preparation_count,
            COUNT(*) FILTER (WHERE fp.status = ANY($3::text[]))::int AS active_count
     FROM foster_placements fp
     JOIN pets p ON p.id = fp.pet_id
     WHERE fp.organization_id = $1
       AND fp.foster_user_id IS NOT NULL
       AND fp.status = ANY($4::text[])
     GROUP BY fp.foster_user_id, p.species`,
    [
      orgId,
      PREPARATION_STATUSES,
      ACTIVE_STATUSES,
      [...PREPARATION_STATUSES, ...ACTIVE_STATUSES],
    ],
  );

  const usage = new Map();
  for (const row of result.rows) {
    const fosterUserId = row.foster_user_id;
    if (!usage.has(fosterUserId)) usage.set(fosterUserId, {});
    usage.get(fosterUserId)[row.species] = {
      preparation: parseInt(row.preparation_count, 10) || 0,
      active: parseInt(row.active_count, 10) || 0,
    };
  }
  return usage;
}

export function fosterHasCapacityForSpecies({
  speciesCapacities,
  usageBySpecies,
  species,
}) {
  const parsed = parseSpeciesCapacities(speciesCapacities);
  const hasDeclaredEntry = parsed.some((entry) => entry.species === species);
  if (!hasDeclaredEntry) {
    return true;
  }
  const declared = declaredCapacityForSpecies(parsed, species);
  if (declared === 0) {
    return false;
  }
  const usage = usageBySpecies[species] || { preparation: 0, active: 0 };
  return availableCapacity(declared, usage.preparation, usage.active) > 0;
}

export function fosterMatchesCompetencyFilter(profileRow, requiredCompetencies = []) {
  if (!requiredCompetencies.length) return true;
  const effective = new Set(effectiveCompetencies(profileRow));
  return requiredCompetencies.every((item) => effective.has(item));
}
