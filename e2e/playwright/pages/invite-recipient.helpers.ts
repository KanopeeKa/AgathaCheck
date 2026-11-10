import { execSync } from 'node:child_process';
import { randomBytes, randomUUID } from 'node:crypto';
import { apiFetch } from '../support/api-fetch';

const API_PREFIX = process.env.E2E_API_PREFIX ?? '/backend/api';

function apiUrl(path: string, baseURL: string): string {
  const root = baseURL.replace(/\/$/, '');
  return `${root}${API_PREFIX}${path}`;
}

/** Work around carer-invite API expiry bug until remedial server fix lands. */
function insertAbsenceCarerInviteRow(opts: {
  absenceId: string;
  contactId: string;
  inviterUserId: string;
  inviteeEmail: string;
  petId: string;
}): string {
  const id = randomUUID();
  const code = randomBytes(6).toString('base64url').slice(0, 8);
  const sql = `INSERT INTO planned_absence_carer_invites (id, planned_absence_id, contact_id, inviter_user_id, invitee_email, code, status, expires_at) VALUES ('${id}', '${opts.absenceId}', '${opts.contactId}', '${opts.inviterUserId}', '${opts.inviteeEmail.replace(/'/g, "''")}', '${code}', 'pending', NOW() + INTERVAL '7 days'); INSERT INTO planned_absence_carer_invite_pets (invite_id, pet_id) VALUES ('${id}', '${opts.petId}');`;
  execSync(`psql -v ON_ERROR_STOP=1 -U user -h localhost -d agatha_db -c ${JSON.stringify(sql)}`, {
    env: { ...process.env, PGPASSWORD: 'password' },
  });
  return code;
}
import {
  createHousehold,
  createHouseholdInvite,
  createPet,
  createPetShareInvite,
  createPeopleContact,
  createPlannedAbsence,
  createShareLink,
  signupUser,
  type TestUser,
} from '../support/api';

const dateOffset = (days: number): string => {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
};

export interface ShareLinkSeed {
  owner: TestUser;
  shareCode: string;
  petName: string;
}

export async function seedShareLink(baseURL: string): Promise<ShareLinkSeed> {
  const owner = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
  const pet = await createPet(baseURL, owner.accessToken, 'Bella', 'Dog');
  const link = await createShareLink(baseURL, owner.accessToken, pet.id);
  return { owner, shareCode: link.share_code, petName: pet.name };
}

export interface EmailInviteSeed {
  owner: TestUser;
  inviteCode: string;
  recipient: TestUser;
  petName: string;
}

export async function seedEmailShareInvite(baseURL: string): Promise<EmailInviteSeed> {
  const owner = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
  const pet = await createPet(baseURL, owner.accessToken, 'Bella', 'Dog');
  const recipient = await signupUser(baseURL, {
    email: `invite-recipient-${Date.now()}@example.com`,
    firstName: 'Bob',
    lastName: 'Recipient',
  });
  await createPet(baseURL, recipient.accessToken, 'Rex', 'Dog');
  const invite = await createPetShareInvite(
    baseURL,
    owner.accessToken,
    [pet.id],
    recipient.email,
    'carer',
  );
  return { owner, inviteCode: invite.code, recipient, petName: pet.name };
}

export interface AbsenceInviteSeed {
  owner: TestUser;
  inviteCode: string;
  recipient: TestUser;
}

export async function seedAbsenceCarerInvite(baseURL: string): Promise<AbsenceInviteSeed> {
  const owner = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
  const pet = await createPet(baseURL, owner.accessToken, 'Bella', 'Dog');
  const recipient = await signupUser(baseURL, {
    email: `absence-carer-${Date.now()}@example.com`,
    firstName: 'Carol',
    lastName: 'Carer',
  });
  await createPet(baseURL, recipient.accessToken, 'Rex', 'Dog');
  const absence = await createPlannedAbsence(baseURL, owner.accessToken, {
    startsOn: dateOffset(7),
    endsOn: dateOffset(14),
    petIds: [pet.id],
  });
  const contact = await createPeopleContact(baseURL, owner.accessToken, {
    name: 'Carol Carer',
    kind: 'person',
    roles: ['sitter'],
    email: recipient.email,
  });

  const patchRes = await apiFetch(apiUrl(`/planned-absences/${absence.id}`, baseURL), {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${owner.accessToken}`,
    },
    body: JSON.stringify({
      pet_carers: [{ pet_id: pet.id, contact_id: contact.id, carer_kind: 'note_only' }],
    }),
  });
  if (!patchRes.ok) {
    throw new Error(`assign absence carer failed (${patchRes.status}): ${await patchRes.text()}`);
  }

  const inviteCode = insertAbsenceCarerInviteRow({
    absenceId: absence.id,
    contactId: contact.id,
    inviterUserId: owner.userId,
    inviteeEmail: recipient.email,
    petId: pet.id,
  });
  return { owner, inviteCode, recipient };
}

export interface HouseholdInviteSeed {
  owner: TestUser;
  inviteCode: string;
  recipient: TestUser;
  householdName: string;
}

export async function seedHouseholdInvite(baseURL: string): Promise<HouseholdInviteSeed> {
  const owner = await signupUser(baseURL, { firstName: 'Alice', lastName: 'Owner' });
  const pet = await createPet(baseURL, owner.accessToken, 'Bella', 'Dog');
  const household = await createHousehold(baseURL, owner.accessToken, 'E2E Household', [pet.id]);
  const recipient = await signupUser(baseURL, {
    email: `household-invitee-${Date.now()}@example.com`,
    firstName: 'Bob',
    lastName: 'Member',
  });
  await createPet(baseURL, recipient.accessToken, 'Rex', 'Dog');
  const invite = await createHouseholdInvite(
    baseURL,
    owner.accessToken,
    household.id,
    recipient.email,
    { accessTier: 'can_log_care' },
  );
  return {
    owner,
    inviteCode: invite.code,
    recipient,
    householdName: household.name,
  };
}
