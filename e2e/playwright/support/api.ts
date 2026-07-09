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

export interface ShareLink {
  share_code: string;
  link_id: string;
}

export interface TestOrganization {
  id: string;
  name: string;
  type: string;
  role: string;
  bio?: string;
}

export interface TestOrgInvite {
  id: string;
  organization_id: string;
  organization_name: string;
  desired_role: string;
}

export interface TestOrgMember {
  id: string;
  user_id: string;
  email: string;
  first_name: string;
  last_name: string;
  role: string;
}

/** Map BDD role labels to API wire values. */
export function mapBddOrgRole(role: string): string {
  switch (role) {
    case 'super_user':
      return 'super_admin';
    case 'member':
      return 'admin';
    case 'foster':
      return 'foster';
    default:
      return role;
  }
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

export async function updateUserProfile(
  baseURL: string,
  token: string,
  data: Partial<{
    first_name: string;
    last_name: string;
    category: string;
    bio: string;
    locale: string;
  }>,
): Promise<TestUser> {
  const res = await fetch(apiUrl('/auth/me', baseURL), {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(data),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`updateUserProfile failed (${res.status}): ${body}`);
  }

  const json = await res.json();
  return {
    email: json.email,
    password: '',
    firstName: json.first_name ?? '',
    lastName: json.last_name ?? '',
    accessToken: token,
    userId: json.id ?? json.user_id,
  };
}

export async function createPet(
  baseURL: string,
  token: string,
  name: string,
  species = 'Dog',
  breed = '',
): Promise<TestPet> {
  const res = await fetch(apiUrl('/pets', baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ name, species, breed }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`createPet failed (${res.status}): ${body}`);
  }

  const json = await res.json();
  return { id: json.id, name: json.name };
}

export async function createOrganization(
  baseURL: string,
  token: string,
  options: {
    name: string;
    type?: 'professional' | 'charity';
    bio?: string;
    email?: string;
  },
): Promise<TestOrganization> {
  const res = await fetch(apiUrl('/organizations', baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      name: options.name,
      type: options.type ?? 'professional',
      bio: options.bio ?? '',
      email: options.email ?? '',
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`createOrganization failed (${res.status}): ${body}`);
  }

  const json = await res.json();
  return {
    id: json.id,
    name: json.name,
    type: json.type,
    role: json.role,
    bio: json.bio,
  };
}

export async function getOrganizations(
  baseURL: string,
  token: string,
): Promise<TestOrganization[]> {
  const res = await fetch(apiUrl('/organizations', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getOrganizations failed (${res.status}): ${body}`);
  }

  return res.json();
}

export async function updateOrganization(
  baseURL: string,
  token: string,
  orgId: string,
  data: Record<string, string>,
): Promise<TestOrganization> {
  const res = await fetch(apiUrl(`/organizations/${orgId}`, baseURL), {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(data),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`updateOrganization failed (${res.status}): ${body}`);
  }

  const json = await res.json();
  return {
    id: json.id ?? orgId,
    name: json.name,
    type: json.type,
    role: json.role,
    bio: json.bio,
  };
}

export async function inviteToOrganization(
  baseURL: string,
  token: string,
  orgId: string,
  options: { email: string; role: string },
): Promise<{ success: boolean; user_id: string }> {
  const res = await fetch(apiUrl(`/organizations/${orgId}/invite`, baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      email: options.email,
      role: mapBddOrgRole(options.role),
    }),
  });

  const body = await res.text();
  if (!res.ok) {
    throw new Error(`inviteToOrganization failed (${res.status}): ${body}`);
  }

  return JSON.parse(body);
}

export async function getPendingInvites(
  baseURL: string,
  token: string,
): Promise<TestOrgInvite[]> {
  const res = await fetch(apiUrl('/organizations/invites/pending', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getPendingInvites failed (${res.status}): ${body}`);
  }

  return res.json();
}

export async function acceptInvite(
  baseURL: string,
  token: string,
  inviteId: string,
): Promise<{ organization_id: string; role: string }> {
  const res = await fetch(apiUrl(`/organizations/invites/${inviteId}/accept`, baseURL), {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`acceptInvite failed (${res.status}): ${body}`);
  }

  return res.json();
}

export async function declineInvite(
  baseURL: string,
  token: string,
  inviteId: string,
): Promise<void> {
  const res = await fetch(apiUrl(`/organizations/invites/${inviteId}/decline`, baseURL), {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`declineInvite failed (${res.status}): ${body}`);
  }
}

export async function getOrgMembers(
  baseURL: string,
  token: string,
  orgId: string,
): Promise<TestOrgMember[]> {
  const res = await fetch(apiUrl(`/organizations/${orgId}/members`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getOrgMembers failed (${res.status}): ${body}`);
  }

  return res.json();
}

export async function leaveOrganization(
  baseURL: string,
  token: string,
  orgId: string,
): Promise<void> {
  const res = await fetch(apiUrl(`/organizations/${orgId}/members/me`, baseURL), {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`leaveOrganization failed (${res.status}): ${body}`);
  }
}

/** Seed org with owner, invite a user, and accept as the invitee. */
export async function seedOrgWithMember(
  baseURL: string,
  owner: TestUser,
  member: TestUser,
  orgName: string,
  memberRole: string = 'member',
): Promise<TestOrganization> {
  const org = await createOrganization(baseURL, owner.accessToken, { name: orgName });
  await inviteToOrganization(baseURL, owner.accessToken, org.id, {
    email: member.email,
    role: memberRole,
  });
  const invites = await getPendingInvites(baseURL, member.accessToken);
  const invite = invites.find((item) => item.organization_id === org.id);
  if (!invite) {
    throw new Error(`No pending invite found for ${orgName}`);
  }
  await acceptInvite(baseURL, member.accessToken, invite.id);
  return org;
}

export async function createShareLink(
  baseURL: string,
  token: string,
  petId: string,
): Promise<ShareLink> {
  const res = await fetch(apiUrl('/share', baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ pet_id: petId }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`createShareLink failed (${res.status}): ${body}`);
  }

  const json = await res.json();
  return { share_code: json.share_code, link_id: json.link_id };
}

// ── Veterinarian helpers ──────────────────────────────────────────────────────

export interface TestVet {
  id: string;
  user_id?: string;
  name: string;
  clinic?: string;
  phone?: string;
  email?: string;
  website?: string;
  address?: string;
  notes?: string;
}

export async function createVet(
  baseURL: string,
  token: string,
  name: string,
): Promise<{ id: string; name: string }> {
  const res = await fetch(apiUrl('/vets', baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ name, clinic: 'E2E Clinic', phone: '555-0100', email: 'vet@example.com' }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`createVet failed (${res.status}): ${body}`);
  }

  const json = await res.json();
  return { id: json.id, name: json.name };
}

export async function createVetFull(
  baseURL: string,
  token: string,
  options: {
    name: string;
    clinic?: string;
    phone?: string;
    email?: string;
    website?: string;
    address?: string;
    notes?: string;
  },
): Promise<TestVet> {
  const res = await fetch(apiUrl('/vets', baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      name: options.name,
      clinic: options.clinic ?? '',
      phone: options.phone ?? '',
      email: options.email ?? '',
      website: options.website ?? '',
      address: options.address ?? '',
      notes: options.notes ?? '',
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`createVetFull failed (${res.status}): ${body}`);
  }

  return res.json() as Promise<TestVet>;
}

export async function getVets(baseURL: string, token: string): Promise<TestVet[]> {
  const res = await fetch(apiUrl('/vets', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getVets failed (${res.status}): ${body}`);
  }

  return res.json() as Promise<TestVet[]>;
}

export async function updateVetDetails(
  baseURL: string,
  token: string,
  vetId: string,
  data: Partial<{
    name: string;
    clinic: string;
    phone: string;
    email: string;
    website: string;
    address: string;
    notes: string;
  }>,
): Promise<TestVet> {
  // PUT requires all fields; fetch the current vet first to fill defaults.
  const current = await (
    await fetch(apiUrl(`/vets/${vetId}`, baseURL), {
      headers: { Authorization: `Bearer ${token}` },
    })
  ).json() as TestVet;

  const res = await fetch(apiUrl(`/vets/${vetId}`, baseURL), {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      name: data.name ?? current.name,
      clinic: data.clinic ?? current.clinic ?? '',
      phone: data.phone ?? current.phone ?? '',
      email: data.email ?? current.email ?? '',
      website: data.website ?? current.website ?? '',
      address: data.address ?? current.address ?? '',
      notes: data.notes ?? current.notes ?? '',
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`updateVetDetails failed (${res.status}): ${body}`);
  }

  return res.json() as Promise<TestVet>;
}

export async function deleteVet(baseURL: string, token: string, vetId: string): Promise<void> {
  const res = await fetch(apiUrl(`/vets/${vetId}`, baseURL), {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`deleteVet failed (${res.status}): ${body}`);
  }
}

export async function acceptShareByCode(
  baseURL: string,
  token: string,
  shareCode: string,
  organizationId?: string,
): Promise<{ pet_id?: string }> {
  const body: Record<string, string> = {};
  if (organizationId) body['organization_id'] = organizationId;

  const res = await fetch(apiUrl(`/share/${shareCode}/accept`, baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`acceptShareByCode failed (${res.status}): ${text}`);
  }

  return res.json() as Promise<{ pet_id?: string }>;
}

export async function updatePetVet(
  baseURL: string,
  token: string,
  petId: string,
  pet: { name: string; species: string; vetId: string },
): Promise<void> {
  const res = await fetch(apiUrl(`/pets/${petId}`, baseURL), {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      name: pet.name,
      species: pet.species,
      breed: '',
      vetId: pet.vetId,
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`updatePetVet failed (${res.status}): ${body}`);
  }
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

export async function updateHealthEntry(
  baseURL: string,
  token: string,
  entryId: string,
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
  const res = await fetch(apiUrl(`/health-entries/${entryId}`, baseURL), {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
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
    throw new Error(`updateHealthEntry failed (${res.status}): ${body}`);
  }

  const json = await res.json();
  return { id: json.id, name: json.name };
}

export async function deleteHealthEntry(
  baseURL: string,
  token: string,
  entryId: string,
): Promise<void> {
  const res = await fetch(apiUrl(`/health-entries/${entryId}`, baseURL), {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`deleteHealthEntry failed (${res.status}): ${body}`);
  }
}

export async function undoCompleteHealthEntry(
  baseURL: string,
  token: string,
  entryId: string,
): Promise<{ status: string; next_due_date: string | null; name: string }> {
  const res = await fetch(apiUrl(`/health-entries/${entryId}/undo-complete`, baseURL), {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`undoCompleteHealthEntry failed (${res.status}): ${body}`);
  }
  return res.json();
}

export async function getHealthEntries(
  baseURL: string,
  token: string,
): Promise<Array<{ id: string; name: string; type: string; status: string; next_due_date: string | null }>> {
  const res = await fetch(apiUrl('/health-entries', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getHealthEntries failed (${res.status}): ${body}`);
  }
  return res.json();
}

export async function exportHealthEntriesCsv(
  baseURL: string,
  token: string,
): Promise<string> {
  const res = await fetch(apiUrl('/health-entries/export', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`exportHealthEntriesCsv failed (${res.status}): ${body}`);
  }
  return res.text();
}

export async function getHealthEntryHistory(
  baseURL: string,
  token: string,
  entryId: string,
): Promise<Array<{ id: string; status: string; completed_on: string | null; changed_at: string }>> {
  const res = await fetch(apiUrl(`/health-entries/${entryId}/history`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getHealthEntryHistory failed (${res.status}): ${body}`);
  }
  return res.json();
}

// ── Notification helpers ──────────────────────────────────────────────────────

export interface TestNotification {
  id: string;
  user_id: string;
  pet_id: string | null;
  pet_name: string | null;
  health_entry_id: string | null;
  organization_id: string | null;
  title: string;
  message: string;
  type: string;
  is_read: boolean;
  created_at: string | null;
}

export async function getNotifications(
  baseURL: string,
  token: string,
): Promise<TestNotification[]> {
  const res = await fetch(apiUrl('/notifications', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getNotifications failed (${res.status}): ${body}`);
  }
  return res.json();
}

export async function getUnreadNotificationCount(
  baseURL: string,
  token: string,
): Promise<number> {
  const res = await fetch(apiUrl('/notifications/unread-count', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getUnreadNotificationCount failed (${res.status}): ${body}`);
  }
  const json = await res.json();
  return json.unread_count as number;
}

export async function markNotificationRead(
  baseURL: string,
  token: string,
  id: string,
): Promise<void> {
  const res = await fetch(apiUrl(`/notifications/${id}/read`, baseURL), {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`markNotificationRead failed (${res.status}): ${body}`);
  }
}

export async function markAllNotificationsRead(
  baseURL: string,
  token: string,
): Promise<void> {
  const res = await fetch(apiUrl('/notifications/read-all', baseURL), {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`markAllNotificationsRead failed (${res.status}): ${body}`);
  }
}

export async function triggerCheckDueNotifications(
  baseURL: string,
  token: string,
): Promise<void> {
  const res = await fetch(apiUrl('/notifications/check-due', baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({}),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`triggerCheckDueNotifications failed (${res.status}): ${body}`);
  }
}

export async function seedOverdueNotification(
  baseURL: string,
  token: string,
  options: { petName?: string; entryName?: string } = {},
): Promise<{ notification: TestNotification; pet: TestPet; entry: TestHealthEntry }> {
  const petName = options.petName ?? 'Bella';
  const entryName = options.entryName ?? 'Vaccination';
  const pet = await createPet(baseURL, token, petName);
  const pastDate = new Date();
  pastDate.setDate(pastDate.getDate() - 7);
  const overdueDate = pastDate.toISOString().slice(0, 10);
  const entry = await createHealthEntry(baseURL, token, pet.id, {
    name: entryName,
    nextDueDate: overdueDate,
  });
  await triggerCheckDueNotifications(baseURL, token);
  const notifications = await getNotifications(baseURL, token);
  const notification = notifications.find(
    (n: TestNotification) => n.health_entry_id === entry.id && n.type === 'overdue',
  );
  if (!notification) {
    throw new Error(`No overdue notification generated for entry: ${entryName}`);
  }
  return { notification, pet, entry };
}

// ── Weight entry helpers ──────────────────────────────────────────────────────

export interface TestWeightEntry {
  id: string;
  pet_id: string;
  pet_name: string | null;
  weight: number;
  unit: string;
  date: string | null;
  notes: string;
  created_at: string | null;
}

export async function createWeightEntry(
  baseURL: string,
  token: string,
  petId: string,
  options: {
    weight: number;
    unit?: 'kg' | 'lb';
    date?: string;
    notes?: string;
  },
): Promise<TestWeightEntry> {
  const date = options.date ?? new Date().toISOString().slice(0, 10);
  const res = await fetch(apiUrl('/weight-entries', baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      pet_id: petId,
      weight: options.weight,
      unit: options.unit ?? 'kg',
      date,
      notes: options.notes ?? '',
    }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`createWeightEntry failed (${res.status}): ${body}`);
  }
  return res.json();
}

export async function getWeightEntries(
  baseURL: string,
  token: string,
  petId: string,
): Promise<TestWeightEntry[]> {
  const res = await fetch(
    apiUrl(`/weight-entries?pet_id=${encodeURIComponent(petId)}`, baseURL),
    { headers: { Authorization: `Bearer ${token}` } },
  );
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getWeightEntries failed (${res.status}): ${body}`);
  }
  return res.json();
}

export async function getLatestWeightEntry(
  baseURL: string,
  token: string,
  petId: string,
): Promise<TestWeightEntry> {
  const res = await fetch(
    apiUrl(`/weight-entries/latest?pet_id=${encodeURIComponent(petId)}`, baseURL),
    { headers: { Authorization: `Bearer ${token}` } },
  );
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getLatestWeightEntry failed (${res.status}): ${body}`);
  }
  return res.json();
}

export async function updateWeightEntry(
  baseURL: string,
  token: string,
  id: string,
  options: { weight: number; unit?: 'kg' | 'lb'; date?: string; notes?: string },
): Promise<TestWeightEntry> {
  const res = await fetch(apiUrl(`/weight-entries/${id}`, baseURL), {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      weight: options.weight,
      unit: options.unit ?? 'kg',
      date: options.date ?? new Date().toISOString().slice(0, 10),
      notes: options.notes ?? '',
    }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`updateWeightEntry failed (${res.status}): ${body}`);
  }
  return res.json();
}

export async function deleteWeightEntry(
  baseURL: string,
  token: string,
  id: string,
): Promise<void> {
  const res = await fetch(apiUrl(`/weight-entries/${id}`, baseURL), {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`deleteWeightEntry failed (${res.status}): ${body}`);
  }
}

// ── Org custody helpers ───────────────────────────────────────────────────────

export async function createOrgPet(
  baseURL: string,
  token: string,
  orgId: string,
  options: { name: string; species?: string },
): Promise<TestPet> {
  const res = await fetch(apiUrl(`/organizations/${orgId}/pets`, baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      name: options.name,
      species: options.species ?? 'dog',
    }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`createOrgPet failed (${res.status}): ${body}`);
  }
  const json = await res.json();
  return { id: json.id, name: json.name };
}

export async function requestCustodyTransfer(
  baseURL: string,
  token: string,
  orgId: string,
  petId: string,
  body: {
    transfer_kind: string;
    to_org_id?: string;
    to_user_id?: string;
    notes?: string;
  },
): Promise<{ id: string; status: string }> {
  const res = await fetch(
    apiUrl(`/organizations/${orgId}/pets/${petId}/custody-transfers`, baseURL),
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(body),
    },
  );
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`requestCustodyTransfer failed (${res.status}): ${text}`);
  }
  return res.json();
}

export async function acceptCustodyTransfer(
  baseURL: string,
  token: string,
  transferId: string,
): Promise<void> {
  const res = await fetch(apiUrl(`/custody-transfers/${transferId}/accept`, baseURL), {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`acceptCustodyTransfer failed (${res.status}): ${text}`);
  }
}

export async function getPendingCustodyTransfers(
  baseURL: string,
  token: string,
): Promise<Array<{ id: string; pet_name?: string; transfer_kind: string }>> {
  const res = await fetch(apiUrl('/custody-transfers/pending', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`getPendingCustodyTransfers failed (${res.status}): ${text}`);
  }
  return res.json();
}

export async function createOrgConnectionRequest(
  baseURL: string,
  token: string,
  orgId: string,
  targetOrgId: string,
): Promise<{ token: string }> {
  const res = await fetch(apiUrl(`/organizations/${orgId}/connection-requests`, baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ target_org_id: targetOrgId }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`createOrgConnectionRequest failed (${res.status}): ${text}`);
  }
  return res.json();
}

export async function acceptOrgConnectionRequest(
  baseURL: string,
  token: string,
  connectionToken: string,
): Promise<void> {
  const res = await fetch(
    apiUrl(`/organizations/connection-requests/${connectionToken}/accept`, baseURL),
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
    },
  );
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`acceptOrgConnectionRequest failed (${res.status}): ${text}`);
  }
}

export async function getOrgArchivedPets(
  baseURL: string,
  token: string,
  orgId: string,
): Promise<Array<{ id: string; pet_name: string; shadow_snapshot?: Record<string, unknown> }>> {
  const res = await fetch(apiUrl(`/organizations/${orgId}/archived`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`getOrgArchivedPets failed (${res.status}): ${text}`);
  }
  return res.json();
}

export async function transferOrgPetToUser(
  baseURL: string,
  token: string,
  orgId: string,
  petId: string,
  recipientEmail: string,
): Promise<{ transfer_id?: string; pending?: boolean }> {
  const res = await fetch(apiUrl(`/organizations/${orgId}/pets/${petId}/transfer`, baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ recipient_email: recipientEmail }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`transferOrgPetToUser failed (${res.status}): ${text}`);
  }
  return res.json();
}

// ── Foster placement helpers (Sprint 6.A) ─────────────────────────────────────

export interface TestFosterPlacement {
  id: string;
  status: string;
  pet_id: string;
  foster_user_id: string;
  organization_id: string;
  pet_name?: string;
}

export interface TestPetDetail {
  id: string;
  name: string;
  organization_id: string | null;
  organization_name?: string | null;
  user_id: string;
  is_foster?: boolean;
  is_shared?: boolean;
}

export async function getPet(
  baseURL: string,
  token: string,
  petId: string,
): Promise<TestPetDetail> {
  const res = await fetch(apiUrl(`/pets/${petId}`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getPet failed (${res.status}): ${body}`);
  }
  return res.json();
}

export async function createFosterPlacement(
  baseURL: string,
  token: string,
  orgId: string,
  petId: string,
  fosterUserId: string,
  options: { startDate?: string; notes?: string } = {},
): Promise<TestFosterPlacement> {
  const res = await fetch(apiUrl(`/organizations/${orgId}/pets/${petId}/placements`, baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      foster_user_id: fosterUserId,
      start_date: options.startDate,
      notes: options.notes ?? '',
    }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`createFosterPlacement failed (${res.status}): ${text}`);
  }
  return res.json();
}

export async function acceptFosterPlacement(
  baseURL: string,
  token: string,
  placementId: string,
): Promise<TestFosterPlacement> {
  const res = await fetch(apiUrl(`/foster-placements/${placementId}/accept`, baseURL), {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`acceptFosterPlacement failed (${res.status}): ${text}`);
  }
  return res.json();
}

export async function getPendingFosterPlacements(
  baseURL: string,
  token: string,
): Promise<TestFosterPlacement[]> {
  const res = await fetch(apiUrl('/foster-placements/pending', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`getPendingFosterPlacements failed (${res.status}): ${text}`);
  }
  return res.json();
}

export async function endFosterPlacement(
  baseURL: string,
  token: string,
  orgId: string,
  placementId: string,
  options: { endDate?: string } = {},
): Promise<TestFosterPlacement> {
  const res = await fetch(
    apiUrl(`/organizations/${orgId}/placements/${placementId}/end`, baseURL),
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ end_date: options.endDate }),
    },
  );
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`endFosterPlacement failed (${res.status}): ${text}`);
  }
  return res.json();
}

export async function initiateDirectAdoption(
  baseURL: string,
  token: string,
  orgId: string,
  petId: string,
  fosterUserId: string,
  options: { adoptionConditions?: string; notes?: string } = {},
): Promise<TestFosterPlacement> {
  const res = await fetch(
    apiUrl(`/organizations/${orgId}/pets/${petId}/placements/direct-adopt`, baseURL),
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        foster_user_id: fosterUserId,
        adoption_conditions: options.adoptionConditions ?? '',
        notes: options.notes ?? '',
      }),
    },
  );
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`initiateDirectAdoption failed (${res.status}): ${text}`);
  }
  return res.json();
}

export async function getPendingAdoptions(
  baseURL: string,
  token: string,
): Promise<TestFosterPlacement[]> {
  const res = await fetch(apiUrl('/foster-placements/pending-adoptions', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`getPendingAdoptions failed (${res.status}): ${text}`);
  }
  return res.json();
}

export async function confirmAdoption(
  baseURL: string,
  token: string,
  placementId: string,
): Promise<TestFosterPlacement & { adopted?: boolean; new_owner_id?: string }> {
  const res = await fetch(apiUrl(`/foster-placements/${placementId}/confirm-adoption`, baseURL), {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`confirmAdoption failed (${res.status}): ${text}`);
  }
  return res.json();
}

export async function requestOrgToOrgTransfer(
  baseURL: string,
  token: string,
  orgId: string,
  petId: string,
  toOrgId: string,
  notes = '',
): Promise<{ id: string; status: string }> {
  return requestCustodyTransfer(baseURL, token, orgId, petId, {
    transfer_kind: 'org_to_org',
    to_org_id: toOrgId,
    notes,
  });
}

export async function tryRequestCustodyTransfer(
  baseURL: string,
  token: string,
  orgId: string,
  petId: string,
  body: {
    transfer_kind: string;
    to_org_id?: string;
    to_user_id?: string;
    notes?: string;
  },
): Promise<{ ok: boolean; status: number; body: unknown }> {
  const res = await fetch(
    apiUrl(`/organizations/${orgId}/pets/${petId}/custody-transfers`, baseURL),
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(body),
    },
  );
  const text = await res.text();
  let parsed: unknown = text;
  try {
    parsed = JSON.parse(text);
  } catch {
    // keep raw text
  }
  return { ok: res.ok, status: res.status, body: parsed };
}

export async function requestPetReturn(
  baseURL: string,
  token: string,
  petId: string,
  toOrgId: string,
  notes = '',
): Promise<{ id: string; status: string }> {
  const res = await fetch(
    apiUrl(`/organizations/${toOrgId}/pets/${petId}/custody-transfers`, baseURL),
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        transfer_kind: 'return_to_org',
        to_org_id: toOrgId,
        notes,
      }),
    },
  );
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`requestPetReturn failed (${res.status}): ${text}`);
  }
  return res.json();
}

export async function disconnectOrgs(
  baseURL: string,
  token: string,
  orgId: string,
  otherOrgId: string,
): Promise<void> {
  const res = await fetch(apiUrl(`/organizations/${orgId}/connections/${otherOrgId}`, baseURL), {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`disconnectOrgs failed (${res.status}): ${text}`);
  }
}

export async function connectOrganizations(
  baseURL: string,
  requesterToken: string,
  requesterOrgId: string,
  targetOrgId: string,
  acceptorToken: string,
): Promise<void> {
  const { token } = await createOrgConnectionRequest(
    baseURL,
    requesterToken,
    requesterOrgId,
    targetOrgId,
  );
  await acceptOrgConnectionRequest(baseURL, acceptorToken, token);
}

export async function hideOrgPetFromHome(
  baseURL: string,
  token: string,
  orgId: string,
  petId: string,
  hidden = true,
): Promise<void> {
  const res = await fetch(apiUrl(`/organizations/${orgId}/pets/${petId}/home-hidden`, baseURL), {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ hidden }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`hideOrgPetFromHome failed (${res.status}): ${text}`);
  }
}

export async function hideFosteredPet(
  baseURL: string,
  token: string,
  petId: string,
  hidden = true,
): Promise<void> {
  const res = await fetch(apiUrl(`/share/${petId}/hide`, baseURL), {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ hidden }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`hideFosteredPet failed (${res.status}): ${text}`);
  }
}

/** Alice super-user + Eve foster parent of Rescue Hearts (BDD Background). */
export async function seedRescueHearts(baseURL: string): Promise<{
  alice: TestUser;
  eve: TestUser;
  org: TestOrganization;
}> {
  const alice = await signupUser(baseURL, {
    firstName: 'Alice',
    lastName: 'Super',
    email: `alice-${Date.now()}@example.com`,
  });
  const eve = await signupUser(baseURL, {
    firstName: 'Eve',
    lastName: 'Foster',
    email: `eve-${Date.now()}@example.com`,
  });
  const org = await createOrganization(baseURL, alice.accessToken, {
    name: 'Rescue Hearts',
    type: 'charity',
  });
  await inviteToOrganization(baseURL, alice.accessToken, org.id, {
    email: eve.email,
    role: 'foster',
  });
  const invites = await getPendingInvites(baseURL, eve.accessToken);
  const invite = invites.find((item) => item.organization_id === org.id);
  if (!invite) {
    throw new Error('No pending foster invite found for Rescue Hearts');
  }
  await acceptInvite(baseURL, eve.accessToken, invite.id);
  return { alice, eve, org };
}

/** Create and accept a foster placement (active in-progress state). */
export async function seedActiveFosterPlacement(
  baseURL: string,
  alice: TestUser,
  eve: TestUser,
  org: TestOrganization,
  petName = 'Max',
): Promise<{ pet: TestPet; placement: TestFosterPlacement }> {
  const pet = await createOrgPet(baseURL, alice.accessToken, org.id, {
    name: petName,
    species: 'dog',
  });
  const placement = await createFosterPlacement(
    baseURL,
    alice.accessToken,
    org.id,
    pet.id,
    eve.userId,
  );
  const accepted = await acceptFosterPlacement(baseURL, eve.accessToken, placement.id);
  return { pet, placement: accepted };
}

// ── Org pet management helpers (Sprint 6.1 BDD) ───────────────────────────────

export interface TestPetSummary {
  id: string;
  name: string;
  organization_id?: string | null;
  organization_name?: string | null;
}

export async function getAllPets(
  baseURL: string,
  token: string,
): Promise<TestPetSummary[]> {
  const res = await fetch(apiUrl('/pets/all', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getAllPets failed (${res.status}): ${body}`);
  }
  return res.json();
}

export interface TestFamilyEvent {
  id: string;
  assigned_to_user_id: string | null;
  assigned_name?: string;
}

export async function getFamilyEvents(
  baseURL: string,
  token: string,
  petId: string,
): Promise<TestFamilyEvent[]> {
  const res = await fetch(apiUrl(`/pets/${petId}/family-events`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getFamilyEvents failed (${res.status}): ${body}`);
  }
  return res.json();
}

export async function createFamilyEvent(
  baseURL: string,
  token: string,
  petId: string,
  options: {
    assignedToUserId: string;
    fromDate?: string;
    eventType?: string;
  },
): Promise<TestFamilyEvent> {
  const fromDate = options.fromDate ?? new Date().toISOString().slice(0, 10);
  const res = await fetch(apiUrl(`/pets/${petId}/family-events`, baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      assigned_to_user_id: options.assignedToUserId,
      from_date: fromDate,
      event_type: options.eventType ?? 'placement',
    }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`createFamilyEvent failed (${res.status}): ${body}`);
  }
  return res.json();
}

/** Alice super-user + Bob member of the same org (BDD Background). */
export async function seedHappyPawsClinic(baseURL: string): Promise<{
  alice: TestUser;
  bob: TestUser;
  org: TestOrganization;
}> {
  const alice = await signupUser(baseURL, {
    firstName: 'Alice',
    lastName: 'Super',
    email: `alice-${Date.now()}@example.com`,
  });
  const bob = await signupUser(baseURL, {
    firstName: 'Bob',
    lastName: 'Member',
    email: `bob-${Date.now()}@example.com`,
  });
  const org = await seedOrgWithMember(baseURL, alice, bob, 'Happy Paws Clinic');
  return { alice, bob, org };
}
