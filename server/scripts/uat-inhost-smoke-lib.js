/**
 * Loopback UAT API smoke — no Apache/Tiger Protect on the wire.
 */

const API_PREFIX = '/backend/api';

function apiUrl(baseUrl, path) {
  const root = baseUrl.replace(/\/$/, '');
  return `${root}${API_PREFIX}${path}`;
}

async function readText(res) {
  return typeof res.text === 'function' ? res.text() : String(res.body ?? '');
}

async function readJson(res) {
  const text = await readText(res);
  return JSON.parse(text);
}

/**
 * @param {string} migrateStatusOutput stdout from `node scripts/migrate.js status`
 * @returns {{ pending: number, ok: boolean }}
 */
export function parseMigrationStatusOutput(migrateStatusOutput) {
  const pendingMatch = migrateStatusOutput.match(/(\d+)\s+pending\.?/i);
  const pending = pendingMatch ? Number(pendingMatch[1]) : 0;
  const hasPendingLine = /\[PENDING\]/i.test(migrateStatusOutput);
  const pendingCount = pending > 0 ? pending : (hasPendingLine ? 1 : 0);
  return { pending: pendingCount, ok: pendingCount === 0 };
}

/**
 * @param {object} opts
 * @param {string} opts.baseUrl e.g. http://127.0.0.1:3456
 * @param {typeof fetch} [opts.fetchImpl]
 * @param {boolean} [opts.quiet]
 */
export async function runInhostApiSmoke({ baseUrl, fetchImpl = fetch, quiet = false }) {
  const log = quiet ? () => {} : (msg) => console.log(msg);

  const healthRes = await fetchImpl(`${baseUrl.replace(/\/$/, '')}/backend/health`);
  if (!healthRes.ok) {
    const body = await readText(healthRes);
    throw new Error(`health check failed (${healthRes.status}): ${body}`);
  }
  log('OK: /backend/health');

  const suffix = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  const email = `uat-inhost-${suffix}@example.com`;
  const password = 'UatInhostPass1';

  const signupRes = await fetchImpl(apiUrl(baseUrl, '/auth/signup'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email,
      password,
      first_name: 'UAT',
      last_name: 'Inhost',
      category: 'pet_guardian',
    }),
  });
  if (!signupRes.ok) {
    const body = await readText(signupRes);
    throw new Error(`signup failed (${signupRes.status}): ${body}`);
  }
  const signupJson = await readJson(signupRes);
  const token = signupJson.access_token;
  if (!token) {
    throw new Error('signup response missing access_token');
  }
  log('OK: signup');

  const petRes = await fetchImpl(apiUrl(baseUrl, '/pets'), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ name: 'InhostPet', species: 'Dog', breed: '' }),
  });
  if (!petRes.ok) {
    const body = await readText(petRes);
    throw new Error(`create pet failed (${petRes.status}): ${body}`);
  }
  const pet = await readJson(petRes);
  log('OK: create pet');

  const nextDue = new Date();
  nextDue.setUTCDate(nextDue.getUTCDate() + 7);
  const nextDueDate = nextDue.toISOString().slice(0, 10);

  const healthResEntry = await fetchImpl(apiUrl(baseUrl, '/health-entries'), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      pet_id: pet.id,
      name: 'Inhost med',
      dosage: '1 tablet',
      frequency: 'monthly',
      frequency_days: 30,
      next_due_date: nextDueDate,
      status: 'active',
      care_family: 'medication',
    }),
  });
  if (!healthResEntry.ok) {
    const body = await readText(healthResEntry);
    throw new Error(`create health entry failed (${healthResEntry.status}): ${body}`);
  }
  log('OK: health entry');

  const petsListRes = await fetchImpl(apiUrl(baseUrl, '/pets'), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!petsListRes.ok) {
    const body = await readText(petsListRes);
    throw new Error(`list pets failed (${petsListRes.status}): ${body}`);
  }
  const petsList = await readJson(petsListRes);
  if (!Array.isArray(petsList) || !petsList.some((p) => p.id === pet.id)) {
    throw new Error('dashboard pets list missing created pet');
  }
  log('OK: dashboard pets read');

  const shareRes = await fetchImpl(apiUrl(baseUrl, '/share'), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ pet_id: pet.id }),
  });
  if (!shareRes.ok) {
    const body = await readText(shareRes);
    throw new Error(`create share link failed (${shareRes.status}): ${body}`);
  }
  const shareJson = await readJson(shareRes);
  const shareCode = shareJson.share_code;
  if (!shareCode) {
    throw new Error('share response missing share_code');
  }

  const previewRes = await fetchImpl(apiUrl(baseUrl, `/share/${shareCode}`));
  if (!previewRes.ok) {
    const body = await readText(previewRes);
    throw new Error(`public share preview failed (${previewRes.status}): ${body}`);
  }
  const preview = await readJson(previewRes);
  if (!preview.pet || preview.pet.name !== pet.name) {
    throw new Error('share preview missing expected pet');
  }
  log('OK: public share preview');

  const deleteRes = await fetchImpl(apiUrl(baseUrl, '/auth/me'), {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ password }),
  });
  if (!deleteRes.ok) {
    const body = await readText(deleteRes);
    throw new Error(`delete account failed (${deleteRes.status}): ${body}`);
  }
  log('OK: account delete');

  return { email, petId: pet.id, shareCode };
}
