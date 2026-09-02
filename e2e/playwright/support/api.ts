/**
 * Thin REST client for seeding E2E data via the Node API.
 * Uses the same single-origin `/backend` prefix as the Flutter web app.
 *
 * Live UAT: set `E2E_TLS_INSECURE=1` in the environment (deploy workflow sets
 * `NODE_TLS_REJECT_UNAUTHORIZED=0`) when cPanel auto-SSL is not trusted by CI runners.
 * On o2switch, call `prepareLiveApiAccess(page)` before seeding so requests reuse
 * the browser WAF session instead of raw Node fetch (blocked with 503).
 */

import { execSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { apiFetch } from './api-fetch';

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

export interface TestHealthOccurrence {
  id: string;
  health_entry_id: string;
  scheduled_date: string;
  scheduled_time: string | null;
  status: string;
  missed?: boolean;
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
      return 'associate';
    default:
      return role;
  }
}

function apiUrl(path: string, baseURL: string): string {
  const root = baseURL.replace(/\/$/, '');
  return `${root}${API_PREFIX}${path}`;
}

function parseJson<T>(text: string): T {
  return JSON.parse(text) as T;
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

  const res = await apiFetch(apiUrl('/auth/signup', baseURL), {
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

  const json = await res.json<{ access_token: string; user: { id: string } }>();
  return {
    email,
    password,
    firstName,
    lastName,
    accessToken: json.access_token,
    userId: json.user.id,
  };
}

export async function getCurrentUser(
  baseURL: string,
  token: string,
): Promise<{ id: string; email: string; bio?: string; first_name?: string; last_name?: string }> {
  const res = await apiFetch(apiUrl('/auth/me', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getCurrentUser failed (${res.status}): ${body}`);
  }
  return res.json<{ id: string; email: string; bio?: string; first_name?: string; last_name?: string }>();
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
  const res = await apiFetch(apiUrl('/auth/me', baseURL), {
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

  const json = await res.json<{
    id?: string;
    user_id?: string;
    email: string;
    first_name?: string;
    last_name?: string;
  }>();
  return {
    email: json.email,
    password: '',
    firstName: json.first_name ?? '',
    lastName: json.last_name ?? '',
    accessToken: token,
    userId: json.id ?? json.user_id ?? '',
  };
}

export interface UserDataExport {
  user: { id: string; email: string };
  pets: Array<{ id: string; name: string }>;
  exported_at: string;
  health_entries?: unknown[];
  vets?: unknown[];
}

export async function exportUserData(
  baseURL: string,
  token: string,
): Promise<UserDataExport> {
  const res = await apiFetch(apiUrl('/auth/me/export', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`exportUserData failed (${res.status}): ${body}`);
  }
  return res.json<UserDataExport>();
}

export async function deleteAccount(
  baseURL: string,
  token: string,
  password: string,
): Promise<void> {
  const res = await apiFetch(apiUrl('/auth/me', baseURL), {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ password }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`deleteAccount failed (${res.status}): ${body}`);
  }
}

export async function tryLogin(
  baseURL: string,
  email: string,
  password: string,
): Promise<{ ok: boolean; status: number }> {
  const res = await apiFetch(apiUrl('/auth/login', baseURL), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  return { ok: res.ok, status: res.status };
}

export async function createPet(
  baseURL: string,
  token: string,
  name: string,
  species = 'Dog',
  breed = '',
): Promise<TestPet> {
  const res = await apiFetch(apiUrl('/pets', baseURL), {
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

  const json = await res.json<TestPet>();
  return { id: json.id, name: json.name };
}

export async function updatePetProfile(
  baseURL: string,
  token: string,
  petId: string,
  data: {
    name: string;
    species: string;
    weight?: number | null;
    breed?: string;
    weightEntryDate?: string;
  },
): Promise<TestPet & { weight?: number | null }> {
  const res = await apiFetch(apiUrl(`/pets/${petId}`, baseURL), {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      breed: '',
      ...data,
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`updatePetProfile failed (${res.status}): ${body}`);
  }

  return res.json<TestPet & { weight?: number | null }>();
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
  const res = await apiFetch(apiUrl('/organizations', baseURL), {
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

  const json = await res.json<TestOrganization>();
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
  const res = await apiFetch(apiUrl('/organizations', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getOrganizations failed (${res.status}): ${body}`);
  }

  return res.json<TestOrganization[]>();
}

export async function updateOrganization(
  baseURL: string,
  token: string,
  orgId: string,
  data: Record<string, string | boolean | Record<string, string>>,
): Promise<TestOrganization> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}`, baseURL), {
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

  const json = await res.json<TestOrganization>();
  return {
    id: json.id ?? orgId,
    name: json.name,
    type: json.type,
    role: json.role,
    bio: json.bio,
  };
}

export interface DiscoverableOrganization {
  id: string;
  name: string;
  type: string;
  logo_url: string;
  photo_url: string;
  display_locality: string;
  town: string;
  administrative_area: string;
  description: string;
}

export interface DiscoverOrganizationsResponse {
  items: DiscoverableOrganization[];
  page: number;
  page_size: number;
  total_count: number;
}

export async function discoverOrganizations(
  baseURL: string,
  options: { page?: number; pageSize?: number; query?: string } = {},
): Promise<DiscoverOrganizationsResponse> {
  const params = new URLSearchParams();
  if (options.page != null) params.set('page', String(options.page));
  if (options.pageSize != null) params.set('page_size', String(options.pageSize));
  if (options.query?.trim()) params.set('q', options.query.trim());
  const qs = params.toString();
  const path = qs ? `/organizations/discover?${qs}` : '/organizations/discover';
  const res = await apiFetch(apiUrl(path, baseURL));

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`discoverOrganizations failed (${res.status}): ${body}`);
  }

  return res.json<DiscoverOrganizationsResponse>();
}

/** Paginate discover results until [orgId] is found (or return undefined). */
export async function findDiscoverableOrganization(
  baseURL: string,
  orgId: string,
): Promise<DiscoverOrganizationsResponse['items'][number] | undefined> {
  let page = 1;
  const pageSize = 50;
  while (true) {
    const discovery = await discoverOrganizations(baseURL, { page, pageSize });
    const match = discovery.items.find((item) => item.id === orgId);
    if (match) return match;
    const fetched = page * discovery.page_size;
    if (fetched >= discovery.total_count || discovery.items.length === 0) {
      return undefined;
    }
    page += 1;
  }
}

export async function setOrganizationDiscoverability(
  baseURL: string,
  token: string,
  org: Pick<TestOrganization, 'id' | 'name' | 'type' | 'bio'>,
  isDiscoverable: boolean,
): Promise<void> {
  await updateOrganization(baseURL, token, org.id, {
    name: org.name,
    type: org.type,
    bio: org.bio ?? '',
    is_discoverable: isDiscoverable,
  });
}

export async function setOrganizationDiscoveryProfile(
  baseURL: string,
  token: string,
  org: Pick<TestOrganization, 'id' | 'name' | 'type' | 'bio'>,
  profile: {
    town?: string;
    administrative_area?: string;
    description?: string;
    logo_url?: string;
    photo_url?: string;
  },
): Promise<void> {
  await updateOrganization(baseURL, token, org.id, {
    name: org.name,
    type: org.type,
    bio: org.bio ?? '',
    town: profile.town ?? '',
    administrative_area: profile.administrative_area ?? '',
    description: profile.description ?? '',
    logo_url: profile.logo_url ?? '',
    photo_url: profile.photo_url ?? '',
  });
}

export interface MemberPrivacyGrants {
  card?: string[];
  phone?: string[];
  email?: string[];
  address?: string[];
}

export interface MemberPrivacySettings {
  card_visibility: string;
  phone_visibility: string;
  email_visibility: string;
  address_visibility: string;
  grants: MemberPrivacyGrants;
}

/** Read per-org member privacy (Account → Organisation settings). */
export async function getMemberPrivacySettings(
  baseURL: string,
  token: string,
  orgId: string,
): Promise<MemberPrivacySettings> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/members/me/privacy`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getMemberPrivacySettings failed (${res.status}): ${body}`);
  }
  return res.json<MemberPrivacySettings>();
}

/** Update per-org member privacy and optional named grants (v3 Account settings). */
export async function updateMemberPrivacySettings(
  baseURL: string,
  token: string,
  orgId: string,
  settings: Partial<{
    card_visibility: string;
    phone_visibility: string;
    email_visibility: string;
    address_visibility: string;
    grants: MemberPrivacyGrants;
  }>,
): Promise<MemberPrivacySettings> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/members/me/privacy`, baseURL), {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(settings),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`updateMemberPrivacySettings failed (${res.status}): ${body}`);
  }
  return res.json<MemberPrivacySettings>();
}

/**
 * Discoverable org for v3 Discover/search journeys.
 * Defaults to no hero photo so tile grids exercise the solid-teal fallback.
 */
export async function seedDiscoverableOrganization(
  baseURL: string,
  overrides: Partial<{
    name: string;
    type: 'charity' | 'professional';
    town: string;
    administrativeArea: string;
    description: string;
    photoUrl: string;
    logoUrl: string;
  }> = {},
): Promise<{ owner: TestUser; org: TestOrganization }> {
  const owner = await signupUser(baseURL, {
    firstName: 'Discover',
    lastName: 'Owner',
    email: `discover-${Date.now()}@example.com`,
  });
  const org = await createOrganization(baseURL, owner.accessToken, {
    name: overrides.name ?? `Discover Org ${Date.now()}`,
    type: overrides.type ?? 'charity',
  });
  await setOrganizationDiscoverability(baseURL, owner.accessToken, org, true);
  await setOrganizationDiscoveryProfile(baseURL, owner.accessToken, org, {
    town: overrides.town ?? 'Springfield',
    administrative_area: overrides.administrativeArea ?? 'Demo County',
    description: overrides.description ?? 'E2E discoverable organisation',
    photo_url: overrides.photoUrl ?? '',
    logo_url: overrides.logoUrl ?? '',
  });
  return { owner, org };
}

export async function inviteToOrganization(
  baseURL: string,
  token: string,
  orgId: string,
  options: { email: string; role: string },
): Promise<{ success: boolean; user_id: string }> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/invite`, baseURL), {
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

  return parseJson<{ success: boolean; user_id: string }>(body);
}

/** Onboard existing org member(s) as foster parent(s) (v4: associate wire + foster badge). */
export async function fosterInviteToOrganization(
  baseURL: string,
  token: string,
  orgId: string,
  options: { userIds: string[] },
): Promise<void> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/foster-invite`, baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ user_ids: options.userIds }),
  });
  const body = await res.text();
  if (!res.ok) {
    throw new Error(`fosterInviteToOrganization failed (${res.status}): ${body}`);
  }
}

export async function getPendingInvites(
  baseURL: string,
  token: string,
): Promise<TestOrgInvite[]> {
  const res = await apiFetch(apiUrl('/organizations/invites/pending', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getPendingInvites failed (${res.status}): ${body}`);
  }

  const raw = await res.json<Array<Record<string, unknown>>>();
  return raw.map((item) => ({
    id: String(item.id),
    organization_id: String(item.organization_id),
    organization_name: String(item.organization_name ?? item.org_name ?? ''),
    desired_role: String(item.desired_role ?? item.role ?? ''),
  }));
}

export async function acceptInvite(
  baseURL: string,
  token: string,
  inviteId: string,
): Promise<{ organization_id: string; role: string }> {
  const res = await apiFetch(apiUrl(`/organizations/invites/${inviteId}/accept`, baseURL), {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`acceptInvite failed (${res.status}): ${body}`);
  }

  return res.json<{ organization_id: string; role: string }>();
}

export async function declineInvite(
  baseURL: string,
  token: string,
  inviteId: string,
): Promise<void> {
  const res = await apiFetch(apiUrl(`/organizations/invites/${inviteId}/decline`, baseURL), {
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
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/members`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getOrgMembers failed (${res.status}): ${body}`);
  }

  return res.json<TestOrgMember[]>();
}

export async function leaveOrganization(
  baseURL: string,
  token: string,
  orgId: string,
): Promise<void> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/members/me`, baseURL), {
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
  const res = await apiFetch(apiUrl('/share', baseURL), {
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

  const json = await res.json<ShareLink>();
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
  const res = await apiFetch(apiUrl('/vets', baseURL), {
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

  const json = await res.json<{ id: string; name: string }>();
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
  const res = await apiFetch(apiUrl('/vets', baseURL), {
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

  return res.json<TestVet>();
}

export async function getVets(baseURL: string, token: string): Promise<TestVet[]> {
  const res = await apiFetch(apiUrl('/vets', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getVets failed (${res.status}): ${body}`);
  }

  return res.json<TestVet[]>();
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
  const getRes = await apiFetch(apiUrl(`/vets/${vetId}`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!getRes.ok) {
    const body = await getRes.text();
    throw new Error(`getVetById failed (${getRes.status}): ${body}`);
  }
  const current = await getRes.json<TestVet>();

  const res = await apiFetch(apiUrl(`/vets/${vetId}`, baseURL), {
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

  return res.json<TestVet>();
}

export async function deleteVet(baseURL: string, token: string, vetId: string): Promise<void> {
  const res = await apiFetch(apiUrl(`/vets/${vetId}`, baseURL), {
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

  const res = await apiFetch(apiUrl(`/share/${shareCode}/accept`, baseURL), {
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

  return res.json<{ pet_id?: string }>();
}

export async function updatePetVet(
  baseURL: string,
  token: string,
  petId: string,
  pet: { name: string; species: string; vetId: string },
): Promise<void> {
  const res = await apiFetch(apiUrl(`/pets/${petId}`, baseURL), {
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
): Promise<{
  status: string;
  completed_on: string | null;
  name: string;
  dosage?: string | null;
  next_due_date?: string | null;
}> {
  const res = await apiFetch(apiUrl(`/health-entries/${entryId}`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getHealthEntry failed (${res.status}): ${body}`);
  }
  return res.json<{
    status: string;
    completed_on: string | null;
    name: string;
    dosage?: string | null;
    next_due_date?: string | null;
  }>();
}

export async function markHealthEntryTaken(
  baseURL: string,
  token: string,
  entryId: string,
  completedOn?: string,
): Promise<void> {
  const res = await apiFetch(apiUrl(`/health-entries/${entryId}/mark-taken`, baseURL), {
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
    scheduleTimes?: string[];
  },
): Promise<TestHealthEntry> {
  const frequency = options.frequency ?? 'monthly';
  const body: Record<string, unknown> = {
    pet_id: petId,
    name: options.name,
    type: options.type ?? 'medication',
    dosage: options.dosage ?? '1 tablet',
    frequency,
    frequency_days: frequency === 'once' ? null : (options.frequencyDays ?? 30),
    next_due_date: options.nextDueDate,
    status: 'active',
  };
  if (options.scheduleTimes != null) {
    body.schedule_times = options.scheduleTimes;
  }
  const res = await apiFetch(apiUrl('/health-entries', baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`createHealthEntry failed (${res.status}): ${body}`);
  }

  const json = await res.json<TestHealthEntry>();
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
  const res = await apiFetch(apiUrl(`/health-entries/${entryId}`, baseURL), {
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

  const json = await res.json<TestHealthEntry>();
  return { id: json.id, name: json.name };
}

export async function deleteHealthEntry(
  baseURL: string,
  token: string,
  entryId: string,
): Promise<void> {
  const res = await apiFetch(apiUrl(`/health-entries/${entryId}`, baseURL), {
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
  const res = await apiFetch(apiUrl(`/health-entries/${entryId}/undo-complete`, baseURL), {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`undoCompleteHealthEntry failed (${res.status}): ${body}`);
  }
  return res.json<{ status: string; next_due_date: string | null; name: string }>();
}

export async function getHealthEntries(
  baseURL: string,
  token: string,
): Promise<Array<{ id: string; name: string; type: string; status: string; next_due_date: string | null }>> {
  const res = await apiFetch(apiUrl('/health-entries', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getHealthEntries failed (${res.status}): ${body}`);
  }
  return res.json<Array<{ id: string; name: string; type: string; status: string; next_due_date: string | null }>>();
}

export async function exportHealthEntriesCsv(
  baseURL: string,
  token: string,
): Promise<string> {
  const res = await apiFetch(apiUrl('/health-entries/export', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`exportHealthEntriesCsv failed (${res.status}): ${body}`);
  }
  return res.text();
}

export async function seedMultiDoseHealthEntry(
  baseURL: string,
  token: string,
  petId: string,
  options: {
    name: string;
    nextDueDate: string;
    scheduleTimes: string[];
  },
): Promise<TestHealthEntry> {
  const entry = await createHealthEntry(baseURL, token, petId, {
    name: options.name,
    type: 'medication',
    nextDueDate: options.nextDueDate,
    frequency: 'daily',
  });

  const { execSync } = await import('node:child_process');
  const { randomUUID } = await import('node:crypto');
  const host = process.env.PGHOST ?? 'localhost';
  const port = process.env.PGPORT ?? '5432';
  const user = process.env.PGUSER ?? 'user';
  const password = process.env.PGPASSWORD ?? 'password';
  const database = process.env.PGDATABASE ?? 'agatha_db';
  const timesArraySql = options.scheduleTimes
    .map((time) => `'${time.replace(/'/g, "''")}'`)
    .join(', ');
  const occValues = options.scheduleTimes
    .map((time) => {
      const occId = randomUUID();
      return `('${occId}', '${entry.id}', '${options.nextDueDate}', '${time}', 'pending')`;
    })
    .join(',\n      ');

  execSync(
    `PGPASSWORD='${password}' psql -h '${host}' -p '${port}' -U '${user}' -d '${database}' -v ON_ERROR_STOP=1 -c "
      UPDATE health_entries
      SET schedule_times = jsonb_build_array(${timesArraySql})
      WHERE id = '${entry.id}';
      DELETE FROM health_occurrences WHERE health_entry_id = '${entry.id}';
      INSERT INTO health_occurrences (id, health_entry_id, scheduled_date, scheduled_time, status)
      VALUES
      ${occValues};
    "`,
    { stdio: 'pipe' },
  );

  return entry;
}

export async function getHealthEntryOccurrences(
  baseURL: string,
  token: string,
  entryId: string,
  options: { status?: 'open' | 'past' } = {},
): Promise<TestHealthOccurrence[]> {
  const qs = options.status ? `?status=${encodeURIComponent(options.status)}` : '';
  const res = await apiFetch(apiUrl(`/health-entries/${entryId}/occurrences${qs}`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getHealthEntryOccurrences failed (${res.status}): ${body}`);
  }
  return res.json<TestHealthOccurrence[]>();
}

export async function completeHealthOccurrence(
  baseURL: string,
  token: string,
  entryId: string,
  occurrenceId: string,
  options: { completedOn?: string; skipEarlierMissed?: boolean } = {},
): Promise<void> {
  const res = await apiFetch(
    apiUrl(`/health-entries/${entryId}/occurrences/${occurrenceId}/complete`, baseURL),
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        completed_on: options.completedOn ?? new Date().toISOString().slice(0, 10),
        skip_earlier_missed: options.skipEarlierMissed ?? false,
      }),
    },
  );
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`completeHealthOccurrence failed (${res.status}): ${body}`);
  }
}

export async function getHealthEntryHistory(
  baseURL: string,
  token: string,
  entryId: string,
): Promise<Array<{ id: string; status: string; completed_on: string | null; changed_at: string }>> {
  const res = await apiFetch(apiUrl(`/health-entries/${entryId}/history`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getHealthEntryHistory failed (${res.status}): ${body}`);
  }
  return res.json<Array<{ id: string; status: string; completed_on: string | null; changed_at: string }>>();
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
  const res = await apiFetch(apiUrl('/notifications', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getNotifications failed (${res.status}): ${body}`);
  }
  return res.json<TestNotification[]>();
}

export async function getUnreadNotificationCount(
  baseURL: string,
  token: string,
): Promise<number> {
  const res = await apiFetch(apiUrl('/notifications/unread-count', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getUnreadNotificationCount failed (${res.status}): ${body}`);
  }
  const json = await res.json<{ unread_count: number }>();
  return json.unread_count;
}

export async function markNotificationRead(
  baseURL: string,
  token: string,
  id: string,
): Promise<void> {
  const res = await apiFetch(apiUrl(`/notifications/${id}/read`, baseURL), {
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
  const res = await apiFetch(apiUrl('/notifications/read-all', baseURL), {
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
  const res = await apiFetch(apiUrl('/notifications/check-due', baseURL), {
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

/** Insert a pet-scoped notification with no health entry (navigates to pet detail). */
export async function seedPetOnlyNotification(
  baseURL: string,
  token: string,
  options: { petName?: string; title?: string } = {},
): Promise<{ notification: TestNotification; pet: TestPet }> {
  const petName = options.petName ?? 'Bella';
  const title = options.title ?? `${petName} reminder`;
  const pet = await createPet(baseURL, token, petName);
  const user = await getCurrentUser(baseURL, token);
  const id = randomUUID();
  const message = `Reminder for ${petName}`;
  const host = process.env.PGHOST ?? 'localhost';
  const port = process.env.PGPORT ?? '5432';
  const pgUser = process.env.PGUSER ?? 'user';
  const password = process.env.PGPASSWORD ?? 'password';
  const database = process.env.PGDATABASE ?? 'agatha_db';
  const esc = (s: string) => s.replace(/'/g, "''");
  execSync(
    `PGPASSWORD='${password}' psql -h '${host}' -p '${port}' -U '${pgUser}' -d '${database}' -c "INSERT INTO notifications (id, user_id, pet_id, pet_name, title, message, type, kind, priority, is_read, read) VALUES ('${id}', '${user.id}', '${pet.id}', '${esc(petName)}', '${esc(title)}', '${esc(message)}', 'general', 'care', 'normal', false, false)"`,
    { stdio: 'pipe' },
  );
  const notifications = await getNotifications(baseURL, token);
  const notification = notifications.find((n: TestNotification) => n.id === id);
  if (!notification) {
    throw new Error(`Pet-only notification not found after insert: ${title}`);
  }
  return { notification, pet };
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
  const res = await apiFetch(apiUrl('/weight-entries', baseURL), {
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
  return res.json<TestWeightEntry>();
}

export async function getWeightEntries(
  baseURL: string,
  token: string,
  petId: string,
): Promise<TestWeightEntry[]> {
  const res = await apiFetch(
    apiUrl(`/weight-entries?pet_id=${encodeURIComponent(petId)}`, baseURL),
    { headers: { Authorization: `Bearer ${token}` } },
  );
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getWeightEntries failed (${res.status}): ${body}`);
  }
  return res.json<TestWeightEntry[]>();
}

export async function getLatestWeightEntry(
  baseURL: string,
  token: string,
  petId: string,
): Promise<TestWeightEntry> {
  const res = await apiFetch(
    apiUrl(`/weight-entries/latest?pet_id=${encodeURIComponent(petId)}`, baseURL),
    { headers: { Authorization: `Bearer ${token}` } },
  );
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getLatestWeightEntry failed (${res.status}): ${body}`);
  }
  return res.json<TestWeightEntry>();
}

export async function updateWeightEntry(
  baseURL: string,
  token: string,
  id: string,
  options: { weight: number; unit?: 'kg' | 'lb'; date?: string; notes?: string },
): Promise<TestWeightEntry> {
  const res = await apiFetch(apiUrl(`/weight-entries/${id}`, baseURL), {
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
  return res.json<TestWeightEntry>();
}

export async function deleteWeightEntry(
  baseURL: string,
  token: string,
  id: string,
): Promise<void> {
  const res = await apiFetch(apiUrl(`/weight-entries/${id}`, baseURL), {
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
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/pets`, baseURL), {
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
  const json = await res.json<TestPet>();
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
  const res = await apiFetch(
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
  return res.json<{ id: string; status: string }>();
}

export async function acceptCustodyTransfer(
  baseURL: string,
  token: string,
  transferId: string,
): Promise<void> {
  const res = await apiFetch(apiUrl(`/custody-transfers/${transferId}/accept`, baseURL), {
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
  const res = await apiFetch(apiUrl('/custody-transfers/pending', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`getPendingCustodyTransfers failed (${res.status}): ${text}`);
  }
  return res.json<Array<{ id: string; pet_name?: string; transfer_kind: string }>>();
}

export async function createOrgConnectionRequest(
  baseURL: string,
  token: string,
  orgId: string,
  targetOrgId: string,
): Promise<{ token: string }> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/connection-requests`, baseURL), {
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
  return res.json<{ token: string }>();
}

export async function acceptOrgConnectionRequest(
  baseURL: string,
  token: string,
  connectionToken: string,
): Promise<void> {
  const res = await apiFetch(
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
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/archived`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`getOrgArchivedPets failed (${res.status}): ${text}`);
  }
  return res.json<Array<{ id: string; pet_name: string; shadow_snapshot?: Record<string, unknown> }>>();
}

export async function transferOrgPetToUser(
  baseURL: string,
  token: string,
  orgId: string,
  petId: string,
  recipientEmail: string,
): Promise<{ transfer_id?: string; pending?: boolean }> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/pets/${petId}/transfer`, baseURL), {
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
  return res.json<{ transfer_id?: string; pending?: boolean }>();
}

// ── Foster placement helpers (Sprint 6.A) ─────────────────────────────────────

export interface TestFosterPlacement {
  id: string;
  status: string;
  session_status?: string;
  pet_id: string;
  foster_user_id: string;
  organization_id: string;
  pet_name?: string;
}

export interface TestPetDetail {
  id: string;
  name: string;
  breed?: string;
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
  const res = await apiFetch(apiUrl(`/pets/${petId}`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getPet failed (${res.status}): ${body}`);
  }
  return res.json<TestPetDetail>();
}

export async function createFosterPlacement(
  baseURL: string,
  token: string,
  orgId: string,
  petId: string,
  fosterUserId: string,
  options: { startDate?: string; endDate?: string; notes?: string } = {},
): Promise<TestFosterPlacement> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/pets/${petId}/placements`, baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      foster_user_id: fosterUserId,
      start_date: options.startDate,
      end_date: options.endDate,
      notes: options.notes ?? '',
    }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`createFosterPlacement failed (${res.status}): ${text}`);
  }
  return res.json<TestFosterPlacement>();
}

export async function acceptFosterPlacement(
  baseURL: string,
  token: string,
  placementId: string,
): Promise<TestFosterPlacement> {
  const res = await apiFetch(apiUrl(`/foster-placements/${placementId}/accept`, baseURL), {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`acceptFosterPlacement failed (${res.status}): ${text}`);
  }
  return res.json<TestFosterPlacement>();
}

export async function getPendingFosterPlacements(
  baseURL: string,
  token: string,
): Promise<TestFosterPlacement[]> {
  const res = await apiFetch(apiUrl('/foster-placements/pending', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`getPendingFosterPlacements failed (${res.status}): ${text}`);
  }
  return res.json<TestFosterPlacement[]>();
}

export type FosterSessionAggregate = TestFosterPlacement & {
  viewer?: { role?: string; allowed_actions?: string[] };
  pet?: { id?: string; name?: string };
  organization?: { id?: string; name?: string };
};

export async function getFosterPlacementDetail(
  baseURL: string,
  token: string,
  placementId: string,
): Promise<FosterSessionAggregate> {
  const res = await apiFetch(apiUrl(`/foster-placements/${placementId}`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`getFosterPlacementDetail failed (${res.status}): ${text}`);
  }
  return res.json<FosterSessionAggregate>();
}

export async function endFosterPlacement(
  baseURL: string,
  token: string,
  orgId: string,
  placementId: string,
  options: { endDate?: string } = {},
): Promise<TestFosterPlacement> {
  const res = await apiFetch(
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
  const placement = await res.json<TestFosterPlacement>();

  // J3 active sessions require a second step to confirm return to shelter.
  if (placement.session_status === 'end_pending_confirmation') {
    const completeRes = await apiFetch(
      apiUrl(`/organizations/${orgId}/placements/${placementId}/end-session`, baseURL),
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          outcome: 'returned_to_shelter',
          end_date: options.endDate,
        }),
      },
    );
    if (!completeRes.ok) {
      const text = await completeRes.text();
      throw new Error(`endFosterPlacement end-session failed (${completeRes.status}): ${text}`);
    }
    return completeRes.json<TestFosterPlacement>();
  }

  return placement;
}

export async function initiateDirectAdoption(
  baseURL: string,
  token: string,
  orgId: string,
  petId: string,
  fosterUserId: string,
  options: { adoptionConditions?: string; notes?: string } = {},
): Promise<TestFosterPlacement> {
  const res = await apiFetch(
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
  return res.json<TestFosterPlacement>();
}

export async function getPendingAdoptions(
  baseURL: string,
  token: string,
): Promise<TestFosterPlacement[]> {
  const res = await apiFetch(apiUrl('/foster-placements/pending-adoptions', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`getPendingAdoptions failed (${res.status}): ${text}`);
  }
  return res.json<TestFosterPlacement[]>();
}

export async function confirmAdoption(
  baseURL: string,
  token: string,
  placementId: string,
): Promise<TestFosterPlacement & { adopted?: boolean; new_owner_id?: string }> {
  const res = await apiFetch(apiUrl(`/foster-placements/${placementId}/confirm-adoption`, baseURL), {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`confirmAdoption failed (${res.status}): ${text}`);
  }
  return res.json<TestFosterPlacement & { adopted?: boolean; new_owner_id?: string }>();
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
  const res = await apiFetch(
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
    parsed = parseJson<unknown>(text);
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
  const res = await apiFetch(
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
  return res.json<{ id: string; status: string }>();
}

export async function disconnectOrgs(
  baseURL: string,
  token: string,
  orgId: string,
  otherOrgId: string,
): Promise<void> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/connections/${otherOrgId}`, baseURL), {
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
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/pets/${petId}/home-hidden`, baseURL), {
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
  const res = await apiFetch(apiUrl(`/share/${petId}/hide`, baseURL), {
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
    role: 'associate',
  });
  const invites = await getPendingInvites(baseURL, eve.accessToken);
  const invite = invites.find((item) => item.organization_id === org.id);
  if (!invite) {
    throw new Error('No pending foster invite found for Rescue Hearts');
  }
  await acceptInvite(baseURL, eve.accessToken, invite.id);
  await fosterInviteToOrganization(baseURL, alice.accessToken, org.id, {
    userIds: [eve.userId],
  });
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

// ── Fostering platform helpers (Wave C) ─────────────────────────────────────

export interface EligibleFosterTarget {
  org_foster_parent_id: string;
  display_name: string;
  email?: string | null;
  eligible?: boolean;
  ineligible_reason?: string | null;
}

export interface TestFosterParent {
  id: string;
  kind: string;
  display_name: string;
  email?: string | null;
  fostering_activity_summary?: string;
  foster_profile_id?: string | null;
}

export interface TestAdoptionVisit {
  id: string;
  pet_id: string;
  fostering_session_id?: string | null;
  status: string;
  visit_outcome?: string | null;
  scheduled_at?: string;
}

export interface TestAdoptionJourney {
  id: string;
  status: string;
  adoption_conditions?: string;
}

export async function getEligibleFosterTargets(
  baseURL: string,
  token: string,
  orgId: string,
  petIds: string[],
): Promise<EligibleFosterTarget[]> {
  const query = petIds.length
    ? `?pet_ids=${encodeURIComponent(petIds.join(','))}`
    : '';
  const res = await apiFetch(
    apiUrl(`/organizations/${orgId}/foster-requests/eligible-targets${query}`, baseURL),
    { headers: { Authorization: `Bearer ${token}` } },
  );
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getEligibleFosterTargets failed (${res.status}): ${body}`);
  }
  return res.json<EligibleFosterTarget[]>();
}

export async function setFosterCapacity(
  fosterProfileId: string,
  speciesCapacities: Array<{ species: string; declared: number }>,
): Promise<void> {
  const { execSync } = await import('node:child_process');
  const host = process.env.PGHOST ?? 'localhost';
  const port = process.env.PGPORT ?? '5432';
  const user = process.env.PGUSER ?? 'user';
  const password = process.env.PGPASSWORD ?? 'password';
  const database = process.env.PGDATABASE ?? 'agatha_db';
  const entries = speciesCapacities
    .map(
      (entry) =>
        `jsonb_build_object('species', '${entry.species}', 'declared', ${entry.declared})`,
    )
    .join(', ');
  execSync(
    `PGPASSWORD='${password}' psql -h '${host}' -p '${port}' -U '${user}' -d '${database}' -c "UPDATE foster_profiles SET species_capacities = jsonb_build_array(${entries}) WHERE id = '${fosterProfileId}'"`,
    { stdio: 'pipe' },
  );
}

export async function addManualFoster(
  baseURL: string,
  token: string,
  orgId: string,
  options: { displayName: string; email: string; phone?: string },
): Promise<TestFosterParent> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/foster-parents`, baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      display_name: options.displayName,
      email: options.email,
      phone: options.phone ?? '',
      lawful_basis_confirmed: true,
    }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`addManualFoster failed (${res.status}): ${body}`);
  }
  return res.json<TestFosterParent>();
}

export async function approveFosterParent(
  baseURL: string,
  token: string,
  orgId: string,
  fosterParentId: string,
): Promise<TestFosterParent> {
  const res = await apiFetch(
    apiUrl(`/organizations/${orgId}/foster-parents/${fosterParentId}/approval`, baseURL),
    {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ approval_state: 'approved' }),
    },
  );
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`approveFosterParent failed (${res.status}): ${body}`);
  }
  return res.json<TestFosterParent>();
}

export async function getFosterParents(
  baseURL: string,
  token: string,
  orgId: string,
): Promise<TestFosterParent[]> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/foster-parents`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getFosterParents failed (${res.status}): ${body}`);
  }
  return res.json<TestFosterParent[]>();
}

export async function createViewToAdoptSession(
  baseURL: string,
  token: string,
  orgId: string,
  petId: string,
  fosterUserId: string,
): Promise<TestFosterPlacement> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/pets/${petId}/placements`, baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      foster_user_id: fosterUserId,
      session_type: 'foster_in_view_to_adopt',
    }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`createViewToAdoptSession failed (${res.status}): ${body}`);
  }
  return res.json<TestFosterPlacement>();
}

export async function createAdoptionVisit(
  baseURL: string,
  token: string,
  orgId: string,
  options: {
    petId: string;
    fosteringSessionId: string;
    scheduledAt?: string;
  },
): Promise<TestAdoptionVisit> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/adoption-visits`, baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      pet_id: options.petId,
      fostering_session_id: options.fosteringSessionId,
      scheduled_at: options.scheduledAt ?? new Date().toISOString(),
    }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`createAdoptionVisit failed (${res.status}): ${body}`);
  }
  return res.json<TestAdoptionVisit>();
}

export async function recordAdoptionVisitOutcome(
  baseURL: string,
  token: string,
  orgId: string,
  visitId: string,
  visitOutcome: 'positive' | 'negative' | 'no_show',
): Promise<TestAdoptionVisit> {
  const res = await apiFetch(
    apiUrl(`/organizations/${orgId}/adoption-visits/${visitId}/outcome`, baseURL),
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ visit_outcome: visitOutcome }),
    },
  );
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`recordAdoptionVisitOutcome failed (${res.status}): ${body}`);
  }
  return res.json<TestAdoptionVisit>();
}

export async function startAdoptionJourney(
  baseURL: string,
  token: string,
  orgId: string,
  placementId: string,
  adoptionConditions = '',
): Promise<{ adoption_journey?: TestAdoptionJourney; placement_id?: string }> {
  const res = await apiFetch(
    apiUrl(`/organizations/${orgId}/placements/${placementId}/start-adoption`, baseURL),
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(
        adoptionConditions ? { adoption_conditions: adoptionConditions } : {},
      ),
    },
  );
  const bodyText = await res.text();
  if (!res.ok) {
    throw new Error(`startAdoptionJourney failed (${res.status}): ${bodyText}`);
  }
  return parseJson<{ adoption_journey?: TestAdoptionJourney; placement_id?: string }>(bodyText);
}

export async function getAdoptionJourney(
  baseURL: string,
  token: string,
  orgId: string,
  placementId: string,
): Promise<{ adoption_journey: TestAdoptionJourney }> {
  const res = await apiFetch(
    apiUrl(`/organizations/${orgId}/placements/${placementId}/adoption-journey`, baseURL),
    { headers: { Authorization: `Bearer ${token}` } },
  );
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getAdoptionJourney failed (${res.status}): ${body}`);
  }
  return res.json<{ adoption_journey: TestAdoptionJourney }>();
}

export async function completeVisitAndStartAdoption(
  baseURL: string,
  token: string,
  orgId: string,
  placementId: string,
  options: { visitId?: string; adoptionConditions?: string } = {},
): Promise<{ adoption_journey?: TestAdoptionJourney }> {
  const res = await apiFetch(
    apiUrl(
      `/organizations/${orgId}/placements/${placementId}/adoption-path/complete-visit-and-start`,
      baseURL,
    ),
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        ...(options.visitId ? { visit_id: options.visitId } : {}),
        ...(options.adoptionConditions
          ? { adoption_conditions: options.adoptionConditions }
          : {}),
      }),
    },
  );
  const bodyText = await res.text();
  if (!res.ok) {
    throw new Error(`completeVisitAndStartAdoption failed (${res.status}): ${bodyText}`);
  }
  return parseJson<{ adoption_journey?: TestAdoptionJourney }>(bodyText);
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
  const res = await apiFetch(apiUrl('/pets/all', baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getAllPets failed (${res.status}): ${body}`);
  }
  return res.json<TestPetSummary[]>();
}

export interface TestFamilyEvent {
  id: string;
  assigned_to_user_id: string | null;
  assigned_name?: string;
  from_date?: string;
  to_date?: string | null;
  notes?: string;
}

export async function getFamilyEvents(
  baseURL: string,
  token: string,
  petId: string,
): Promise<TestFamilyEvent[]> {
  const res = await apiFetch(apiUrl(`/pets/${petId}/family-events`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getFamilyEvents failed (${res.status}): ${body}`);
  }
  return res.json<TestFamilyEvent[]>();
}

export async function createFamilyEvent(
  baseURL: string,
  token: string,
  petId: string,
  options: {
    assignedToUserId: string;
    fromDate?: string;
    toDate?: string;
    notes?: string;
    eventType?: string;
  },
): Promise<TestFamilyEvent> {
  const fromDate = options.fromDate ?? new Date().toISOString().slice(0, 10);
  const body: Record<string, string> = {
    assigned_to_user_id: options.assignedToUserId,
    from_date: fromDate,
    event_type: options.eventType ?? 'placement',
  };
  if (options.toDate) body.to_date = options.toDate;
  if (options.notes) body.notes = options.notes;

  const res = await apiFetch(apiUrl(`/pets/${petId}/family-events`, baseURL), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const bodyText = await res.text();
    throw new Error(`createFamilyEvent failed (${res.status}): ${bodyText}`);
  }
  return res.json<TestFamilyEvent>();
}

export async function deleteFamilyEvent(
  baseURL: string,
  token: string,
  petId: string,
  eventId: string,
): Promise<void> {
  const res = await apiFetch(apiUrl(`/pets/${petId}/family-events/${eventId}`, baseURL), {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const bodyText = await res.text();
    throw new Error(`deleteFamilyEvent failed (${res.status}): ${bodyText}`);
  }
}

export interface OrgPersonSummary {
  kind: string;
  record_id: string;
  user_id?: string;
  display_name: string;
  email?: string;
  role?: string;
  phone?: string;
  message_allowed?: boolean;
}

export async function getOrgPeople(
  baseURL: string,
  token: string,
  orgId: string,
): Promise<OrgPersonSummary[]> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/people`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getOrgPeople failed (${res.status}): ${body}`);
  }
  return res.json<OrgPersonSummary[]>();
}

export async function updateOrgPersonContact(
  baseURL: string,
  token: string,
  orgId: string,
  kind: 'member' | 'external',
  personId: string,
  contact: {
    phone?: string;
    foster_phone?: string;
    notes?: string;
    admin_notes?: string;
    foster_address?: string;
    display_name?: string;
    email?: string;
  },
): Promise<Record<string, unknown>> {
  const body = {
    ...contact,
    foster_phone: contact.foster_phone ?? contact.phone,
    admin_notes: contact.admin_notes ?? contact.notes,
  };
  delete (body as { phone?: string }).phone;
  delete (body as { notes?: string }).notes;

  const res = await apiFetch(
    apiUrl(`/organizations/${orgId}/people/${kind}/${personId}/contact`, baseURL),
    {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(body),
    },
  );
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`updateOrgPersonContact failed (${res.status}): ${body}`);
  }
  return res.json<Record<string, unknown>>();
}

export interface OrgConnectionRow {
  id: string;
  peer_org_id: string;
  peer_org_name: string;
  peer_org_email?: string;
}

export async function getOrgConnections(
  baseURL: string,
  token: string,
  orgId: string,
): Promise<OrgConnectionRow[]> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/connections`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getOrgConnections failed (${res.status}): ${body}`);
  }
  return res.json<OrgConnectionRow[]>();
}

export interface OrgPermissionsMe {
  role: string;
  effective_permissions: string[];
}

export async function getOrgPermissionsMe(
  baseURL: string,
  token: string,
  orgId: string,
): Promise<OrgPermissionsMe> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/permissions/me`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getOrgPermissionsMe failed (${res.status}): ${body}`);
  }
  return res.json<OrgPermissionsMe>();
}

export async function applyOrgPermissionBundle(
  baseURL: string,
  token: string,
  orgId: string,
  targetUserId: string,
  preset: string,
): Promise<{ preset: string; granted_count: number; effective_permissions: string[] }> {
  const res = await apiFetch(
    apiUrl(`/organizations/${orgId}/members/${targetUserId}/permissions/bundle`, baseURL),
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ preset }),
    },
  );
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`applyOrgPermissionBundle failed (${res.status}): ${body}`);
  }
  return res.json<{ preset: string; granted_count: number; effective_permissions: string[] }>();
}

export async function tryGrantOrgPermission(
  baseURL: string,
  token: string,
  orgId: string,
  targetUserId: string,
  permissionKey: string,
): Promise<{ ok: boolean; status: number }> {
  const res = await apiFetch(
    apiUrl(`/organizations/${orgId}/members/${targetUserId}/permissions`, baseURL),
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ permission_key: permissionKey }),
    },
  );
  return { ok: res.ok, status: res.status };
}

export interface OrgAuditEvent {
  id: string;
  action: string;
  occurred_at: string;
  metadata?: Record<string, unknown>;
}

export async function getOrgAuditEvents(
  baseURL: string,
  token: string,
  orgId: string,
): Promise<OrgAuditEvent[]> {
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/audit-events`, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getOrgAuditEvents failed (${res.status}): ${body}`);
  }
  return res.json<OrgAuditEvent[]>();
}

export async function getOrgPublicProfile(
  baseURL: string,
  orgId: string,
  token?: string,
): Promise<Record<string, unknown>> {
  const headers: Record<string, string> = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/public`, baseURL), { headers });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getOrgPublicProfile failed (${res.status}): ${body}`);
  }
  return res.json<Record<string, unknown>>();
}

export async function tryGetOrgPublicProfile(
  baseURL: string,
  orgId: string,
  token?: string,
): Promise<{ ok: boolean; status: number; body?: Record<string, unknown> }> {
  const headers: Record<string, string> = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await apiFetch(apiUrl(`/organizations/${orgId}/public`, baseURL), { headers });
  if (!res.ok) {
    return { ok: false, status: res.status };
  }
  return { ok: true, status: res.status, body: await res.json<Record<string, unknown>>() };
}

export interface OrgFosteringSessionRow {
  id: string;
  pet_name: string;
  foster_name: string;
  foster_email: string;
  derived_status?: string;
  nearly_finished?: boolean;
}

export async function getOrgPlacements(
  baseURL: string,
  token: string,
  orgId: string,
  query: { derived_status?: string; pet_name?: string; foster_name?: string } = {},
): Promise<OrgFosteringSessionRow[]> {
  const params = new URLSearchParams();
  if (query.derived_status) params.set('derived_status', query.derived_status);
  if (query.pet_name) params.set('pet_name', query.pet_name);
  if (query.foster_name) params.set('foster_name', query.foster_name);
  const qs = params.toString();
  const path = qs
    ? `/organizations/${orgId}/placements?${qs}`
    : `/organizations/${orgId}/placements`;
  const res = await apiFetch(apiUrl(path, baseURL), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getOrgPlacements failed (${res.status}): ${body}`);
  }
  return res.json<OrgFosteringSessionRow[]>();
}

export interface RedactedOrgPet {
  id: string;
  name: string;
  species: string;
  breed: string;
  photo_path: string | null;
  date_of_birth: string | null;
  age: number | null;
  organization_id: string;
}

export async function getRedactedOrgPet(
  baseURL: string,
  token: string,
  orgId: string,
  petId: string,
): Promise<RedactedOrgPet> {
  const res = await apiFetch(
    apiUrl(`/organizations/${orgId}/pets/${petId}/redacted`, baseURL),
    { headers: { Authorization: `Bearer ${token}` } },
  );
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`getRedactedOrgPet failed (${res.status}): ${body}`);
  }
  return res.json<RedactedOrgPet>();
}

export async function tryGetRedactedOrgPet(
  baseURL: string,
  token: string,
  orgId: string,
  petId: string,
): Promise<{ ok: boolean; status: number; body?: RedactedOrgPet }> {
  const res = await apiFetch(
    apiUrl(`/organizations/${orgId}/pets/${petId}/redacted`, baseURL),
    { headers: { Authorization: `Bearer ${token}` } },
  );
  if (!res.ok) {
    return { ok: false, status: res.status };
  }
  return { ok: true, status: res.status, body: await res.json<RedactedOrgPet>() };
}

/** Invite an existing user and accept membership (BDD org journeys). */
export async function addMemberToOrg(
  baseURL: string,
  ownerToken: string,
  orgId: string,
  member: TestUser,
  role: string,
): Promise<void> {
  await inviteToOrganization(baseURL, ownerToken, orgId, {
    email: member.email,
    role: mapBddOrgRole(role),
  });
  const invites = await getPendingInvites(baseURL, member.accessToken);
  const invite = invites.find((item) => item.organization_id === orgId);
  if (!invite) {
    throw new Error(`No pending invite for org ${orgId}`);
  }
  await acceptInvite(baseURL, member.accessToken, invite.id);
}

/** Dual-role user: personal pet + organisation membership (BDD experience journeys). */
export async function seedDualRoleUser(
  baseURL: string,
  overrides: Partial<{
    email: string;
    password: string;
    firstName: string;
    lastName: string;
    petName: string;
    orgName: string;
  }> = {},
): Promise<{ user: TestUser; org: TestOrganization; pet: TestPet }> {
  const user = await signupUser(baseURL, overrides);
  const pet = await createPet(
    baseURL,
    user.accessToken,
    overrides.petName ?? 'Personal Pet',
  );
  const org = await createOrganization(baseURL, user.accessToken, {
    name: overrides.orgName ?? `E2E Rescue ${Date.now()}`,
  });
  return { user, org, pet };
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
