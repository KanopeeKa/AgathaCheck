/**
 * API seed helpers for pet-profile BDD specs (avoids extending api.ts).
 */
import { apiFetch } from '../support/api-fetch';

const API_PREFIX = process.env.E2E_API_PREFIX ?? '/backend/api';

/** Matches server/routes/pets/shared.js PET_COLOR_PALETTE (15 colors). */
export const PET_COLOR_PALETTE = [
  0xff7e57c2, 0xff9575cd, 0xff5c6bc0, 0xff7986cb, 0xff4db6ac,
  0xff81c784, 0xff4fc3f7, 0xffba68c8, 0xfff06292, 0xffe57373,
  0xffffb74d, 0xffa1887f, 0xff90a4ae, 0xff64b5f6, 0xffaed581,
];

/** 1×1 PNG — valid image for photoPath wire tests. */
export const TINY_PNG_BASE64 =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

function apiUrl(path: string, baseURL: string): string {
  return `${baseURL.replace(/\/$/, '')}${API_PREFIX}${path}`;
}

export interface PetRecord {
  id: string;
  name: string;
  species?: string;
  breed?: string;
  colorValue?: number;
  dateOfBirth?: string | null;
  chipId?: string;
  photoPath?: string | null;
  passedAway?: boolean;
  vetId?: string | null;
}

export async function getPetRecord(
  baseURL: string,
  token: string,
  petId: string,
): Promise<PetRecord> {
  const res = await apiFetch(apiUrl(`/pets/${petId}`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    throw new Error(`getPetRecord failed (${res.status}): ${await res.text()}`);
  }
  return res.json() as Promise<PetRecord>;
}

export async function updatePetFields(
  baseURL: string,
  token: string,
  petId: string,
  fields: {
    name: string;
    species: string;
    breed?: string;
    dateOfBirth?: string | null;
    chipId?: string;
    photoPath?: string | null;
    passedAway?: boolean;
    vetId?: string | null;
  },
): Promise<PetRecord> {
  const current = await getPetRecord(baseURL, token, petId);
  const res = await apiFetch(apiUrl(`/pets/${petId}`, baseURL), {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      name: fields.name,
      species: fields.species,
      breed: fields.breed ?? current.breed ?? '',
      dateOfBirth: fields.dateOfBirth ?? current.dateOfBirth ?? null,
      chipId: fields.chipId ?? current.chipId ?? '',
      photoPath: fields.photoPath ?? current.photoPath ?? null,
      passedAway: fields.passedAway ?? current.passedAway ?? false,
      vetId: fields.vetId ?? current.vetId ?? null,
      weight: (current as { weight?: number | null }).weight ?? null,
      gender: (current as { gender?: string | null }).gender ?? null,
      bio: '',
      insurance: '',
      chipDismissed: false,
      neuterDismissed: false,
    }),
  });
  if (!res.ok) {
    throw new Error(`updatePetFields failed (${res.status}): ${await res.text()}`);
  }
  return res.json() as Promise<PetRecord>;
}

export async function fetchPendingShares(
  baseURL: string,
  token: string,
): Promise<unknown[]> {
  const res = await apiFetch(apiUrl('/share/pending', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    throw new Error(`fetchPendingShares failed (${res.status}): ${await res.text()}`);
  }
  return res.json() as Promise<unknown[]>;
}

export async function declinePendingShareApi(
  baseURL: string,
  token: string,
  petId: string,
): Promise<number> {
  const res = await apiFetch(apiUrl(`/share/pending/${petId}/decline`, baseURL), {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
  });
  return res.status;
}

export async function acceptPendingShareApi(
  baseURL: string,
  token: string,
  petId: string,
  organizationId?: string,
): Promise<number> {
  const body: Record<string, string> = {};
  if (organizationId) body.organization_id = organizationId;
  const res = await apiFetch(apiUrl(`/share/pending/${petId}/accept`, baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(body),
  });
  return res.status;
}
