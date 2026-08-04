import { DEMO_PASSWORD_HASH } from './demo-constants.js';

/** Format a calendar date as YYYY-MM-DD relative to today. */
export function calendarDaysFromToday(offsetDays) {
  const date = new Date();
  date.setUTCHours(12, 0, 0, 0);
  date.setUTCDate(date.getUTCDate() + offsetDays);
  return date.toISOString().slice(0, 10);
}

/** ISO timestamp relative to now. */
export function timestampFromNow(offsetDays = 0) {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + offsetDays);
  return date.toISOString();
}

export async function upsertUser(client, user) {
  await client.query(
    `INSERT INTO users (id, email, password_hash, first_name, last_name, category, bio)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     ON CONFLICT (id) DO UPDATE SET
       email = EXCLUDED.email,
       password_hash = EXCLUDED.password_hash,
       first_name = EXCLUDED.first_name,
       last_name = EXCLUDED.last_name,
       category = EXCLUDED.category,
       bio = EXCLUDED.bio,
       updated_at = NOW()`,
    [
      user.id,
      user.email,
      DEMO_PASSWORD_HASH,
      user.first_name,
      user.last_name,
      user.category,
      user.bio || '',
    ],
  );
}

export async function upsertOrganization(client, org) {
  await client.query(
    `INSERT INTO organizations (
       id, name, type, bio, email, phone, town, administrative_area,
       description, is_discoverable, photo_url, logo_url
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       type = EXCLUDED.type,
       bio = EXCLUDED.bio,
       email = EXCLUDED.email,
       phone = EXCLUDED.phone,
       town = EXCLUDED.town,
       administrative_area = EXCLUDED.administrative_area,
       description = EXCLUDED.description,
       is_discoverable = EXCLUDED.is_discoverable,
       photo_url = EXCLUDED.photo_url,
       logo_url = EXCLUDED.logo_url,
       updated_at = NOW()`,
    [
      org.id,
      org.name,
      org.type,
      org.bio || '',
      org.email || null,
      org.phone || null,
      org.town || null,
      org.administrative_area || null,
      org.description || null,
      org.is_discoverable !== false,
      org.photo_url ?? '',
      org.logo_url ?? '',
    ],
  );
}

export async function upsertOrgMember(client, { id, orgId, userId, role }) {
  await client.query(
    `INSERT INTO organization_users (id, organization_id, user_id, role)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (organization_id, user_id) DO UPDATE SET role = EXCLUDED.role`,
    [id, orgId, userId, role],
  );
}

export async function upsertPersonalPet(client, pet) {
  await client.query(
    `INSERT INTO pets (
       id, user_id, name, species, breed, date_of_birth, weight, gender,
       bio, vet_id, care_holder_kind, care_holder_user_id
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'user', $2)
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       species = EXCLUDED.species,
       breed = EXCLUDED.breed,
       date_of_birth = EXCLUDED.date_of_birth,
       weight = EXCLUDED.weight,
       gender = EXCLUDED.gender,
       bio = EXCLUDED.bio,
       vet_id = EXCLUDED.vet_id,
       user_id = EXCLUDED.user_id,
       care_holder_kind = EXCLUDED.care_holder_kind,
       care_holder_user_id = EXCLUDED.care_holder_user_id,
       updated_at = NOW()`,
    [
      pet.id,
      pet.userId,
      pet.name,
      pet.species,
      pet.breed || '',
      pet.dateOfBirth || null,
      pet.weight ?? null,
      pet.gender || null,
      pet.bio || '',
      pet.vetId || null,
    ],
  );
}

export async function upsertOrgPet(client, pet) {
  await client.query(
    `INSERT INTO pets (
       id, user_id, name, species, breed, date_of_birth, weight, gender,
       bio, organization_id, care_holder_kind, care_holder_org_id
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'org', $10)
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       species = EXCLUDED.species,
       breed = EXCLUDED.breed,
       date_of_birth = EXCLUDED.date_of_birth,
       weight = EXCLUDED.weight,
       gender = EXCLUDED.gender,
       bio = EXCLUDED.bio,
       organization_id = EXCLUDED.organization_id,
       care_holder_kind = EXCLUDED.care_holder_kind,
       care_holder_org_id = EXCLUDED.care_holder_org_id,
       updated_at = NOW()`,
    [
      pet.id,
      pet.userId,
      pet.name,
      pet.species,
      pet.breed || '',
      pet.dateOfBirth || null,
      pet.weight ?? null,
      pet.gender || null,
      pet.bio || '',
      pet.orgId,
    ],
  );
}
