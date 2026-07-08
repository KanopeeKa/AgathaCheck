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
