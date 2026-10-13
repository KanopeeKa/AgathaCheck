/**
 * API seed helpers for Agatha care journey E2E (avoids extending pet-profile.seed).
 */
import { apiFetch } from '../support/api-fetch';
import { getPetRecord } from './pet-profile.seed';

const API_PREFIX = process.env.E2E_API_PREFIX ?? '/backend/api';

function apiUrl(path: string, baseURL: string): string {
  return `${baseURL.replace(/\/$/, '')}${API_PREFIX}${path}`;
}

export interface WelfareSuggestionWire {
  id: string;
  subject_key: string;
  dedupe_key: string;
  status: string;
}

async function putPetProfileFacts(
  baseURL: string,
  token: string,
  petId: string,
  patch: {
    name: string;
    species: string;
    identificationStatus?: 'unknown' | 'yes' | 'no';
    chipId?: string;
  },
): Promise<void> {
  const current = await getPetRecord(baseURL, token, petId);
  const res = await apiFetch(apiUrl(`/pets/${petId}`, baseURL), {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      name: patch.name,
      species: patch.species,
      breed: current.breed ?? '',
      dateOfBirth: current.dateOfBirth ?? null,
      chipId: patch.chipId ?? current.chipId ?? '',
      photoPath: current.photoPath ?? null,
      passedAway: current.passedAway ?? false,
      vetId: current.vetId ?? null,
      weight: (current as { weight?: number | null }).weight ?? null,
      gender: (current as { gender?: string | null }).gender ?? null,
      bio: '',
      insurance: '',
      chipDismissed: false,
      neuterDismissed: false,
      ...(patch.identificationStatus !== undefined
        ? { identificationStatus: patch.identificationStatus }
        : {}),
    }),
  });
  if (!res.ok) {
    throw new Error(`putPetProfileFacts failed (${res.status}): ${await res.text()}`);
  }
}

export async function listPendingWelfareSuggestions(
  baseURL: string,
  token: string,
  petId: string,
): Promise<WelfareSuggestionWire[]> {
  const res = await apiFetch(apiUrl(`/pets/${petId}/welfare-suggestions`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    throw new Error(`listPendingWelfareSuggestions failed (${res.status}): ${await res.text()}`);
  }
  return res.json() as Promise<WelfareSuggestionWire[]>;
}

export async function seedMicrochipWelfarePending(
  baseURL: string,
  token: string,
  petId: string,
  petName: string,
  species: string,
): Promise<void> {
  await putPetProfileFacts(baseURL, token, petId, {
    name: petName,
    species,
    identificationStatus: 'no',
    chipId: '',
  });
  await listPendingWelfareSuggestions(baseURL, token, petId);
}

export async function saveMicrochipOnProfile(
  baseURL: string,
  token: string,
  petId: string,
  petName: string,
  species: string,
  chipId: string,
): Promise<void> {
  await putPetProfileFacts(baseURL, token, petId, {
    name: petName,
    species,
    identificationStatus: 'yes',
    chipId,
  });
}
