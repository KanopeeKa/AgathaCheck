/**
 * Thin REST client for seeding E2E data via the Node API.
 * Uses the same single-origin `/backend` prefix as the Flutter web app.
 *
 * Live UAT: set `E2E_TLS_INSECURE=1` in the environment (deploy workflow sets
 * `NODE_TLS_REJECT_UNAUTHORIZED=0`) when cPanel auto-SSL is not trusted by CI runners.
 */

const API_PREFIX = process.env.E2E_API_PREFIX ?? '/backend/api';

export interface TestUser {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  accessToken: string;
  userId: string;
}

export interface TestPet {
  id: string;
  name: string;
}

export interface TestHealthEntry {
  id: string;
  name: string;
}

function apiUrl(path: string, baseURL: string): string {
  const root = baseURL.replace(/\/$/, '');
  return `${root}${API_PREFIX}${path}`;
}

export async function signupUser(
  baseURL: string,
  overrides: Partial<{
    email: string;
    password: string;
    firstName: string;
    lastName: string;
  }> = {},
): Promise<TestUser> {
  const suffix = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  const email = overrides.email ?? `e2e-${suffix}@example.com`;
  const password = overrides.password ?? 'E2eTestPass1';
  const firstName = overrides.firstName ?? 'E2E';
  const lastName = overrides.lastName ?? 'User';

  const res = await fetch(apiUrl('/auth/signup', baseURL), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email,
      password,
      first_name: firstName,
      last_name: lastName,
      category: 'pet_guardian',
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`signup failed (${res.status}): ${body}`);
  }

  const json = await res.json();
  return {
    email,
    password,
    firstName,
    lastName,
    accessToken: json.access_token,
    userId: json.user.id,
  };
}

export async function createPet(
  baseURL: string,
  token: string,
  name: string,
  species = 'Dog',
): Promise<TestPet> {
  const res = await fetch(apiUrl('/pets', baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ name, species, breed: '' }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`createPet failed (${res.status}): ${body}`);
  }

  const json = await res.json();
  return { id: json.id, name: json.name };
}

export async function getHealthEntry(
  baseURL: string,
  token: string,
  entryId: string,
): Promise<{ status: string; completed_on: string | null; name: string }> {
  const res = await fetch(apiUrl(`/health-entries/${entryId}`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getHealthEntry failed (${res.status}): ${body}`);
  }
  return res.json();
}

export async function markHealthEntryTaken(
  baseURL: string,
  token: string,
  entryId: string,
  completedOn?: string,
): Promise<void> {
  const res = await fetch(apiUrl(`/health-entries/${entryId}/mark-taken`, baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      completed_on: completedOn ?? new Date().toISOString().slice(0, 10),
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`markHealthEntryTaken failed (${res.status}): ${body}`);
  }
}
export async function createHealthEntry(
  baseURL: string,
  token: string,
  petId: string,
  options: {
    name: string;
    type?: string;
    nextDueDate: string;
    dosage?: string;
    frequency?: string;
    frequencyDays?: number;
  },
): Promise<TestHealthEntry> {
  const frequency = options.frequency ?? 'monthly';
  const res = await fetch(apiUrl('/health-entries', baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      pet_id: petId,
      name: options.name,
      type: options.type ?? 'medication',
      dosage: options.dosage ?? '1 tablet',
      frequency,
      frequency_days: frequency === 'once' ? null : (options.frequencyDays ?? 30),
      next_due_date: options.nextDueDate,
      status: 'active',
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`createHealthEntry failed (${res.status}): ${body}`);
  }

  const json = await res.json();
  return { id: json.id, name: json.name };
}
