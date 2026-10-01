/**
 * Care occurrences UAT dataset (care-next-occurrence-c1a7 §6.4).
 *
 * Every occurrence is created by the same commands as the app, replayed at
 * past pet-home clocks (Europe/Paris), so UAT shows each behaviour: Today with
 * time groups, Overdue first, a Not recorded stack, a planned booster, the
 * month-end clamp, a remembered next-date choice, a paused item.
 */
import { DEMO_IDS } from '../demo-constants.js';
import {
  SEED_PET_TIMEZONE,
  catchUp,
  clockAt,
  completeEarliest,
  createSeedCareItem,
  dayFrom,
  postpone,
  recordDay,
  seedNow,
} from '../helpers/care-commands.js';

const OWNER = DEMO_IDS.alice;

/** Most recent 31st on or before `todayIso`. */
function lastThirtyFirst(todayIso) {
  let [y, m] = todayIso.split('-').map(Number);
  const d = Number(todayIso.slice(8, 10));
  if (d === 31) return todayIso;
  for (let i = 0; i < 12; i += 1) {
    m -= 1;
    if (m === 0) { m = 12; y -= 1; }
    if (new Date(Date.UTC(y, m, 0)).getUTCDate() === 31) {
      return `${y}-${String(m).padStart(2, '0')}-31`;
    }
  }
  return todayIso;
}

/** Facts asserted by server/test/db/seeds/careOccurrencesSeed.test.js. */
export function careOccurrencesSeedFacts() {
  return {
    buddy: {
      apoquel: DEMO_IDS.coBuddyApoquel,
      heartTablet: DEMO_IDS.coBuddyHeartTablet,
      nexgard: DEMO_IDS.coBuddyNexgard,
      dhpp: DEMO_IDS.coBuddyDhpp,
      rabies: DEMO_IDS.coBuddyRabies,
      wellness: DEMO_IDS.buddyOverduePreventive,
      dentalChew: DEMO_IDS.coBuddyDentalChew,
      grooming: DEMO_IDS.coBuddyGrooming,
    },
    whiskers: {
      methimazole: DEMO_IDS.coWhiskersMethimazole,
      flea: DEMO_IDS.coWhiskersFlea,
      nailTrim: DEMO_IDS.coWhiskersNailTrim,
      vaccination: DEMO_IDS.coWhiskersVaccination,
      weighIn: DEMO_IDS.coWhiskersWeighIn,
      vetVisit: DEMO_IDS.whiskersVetVisit,
    },
  };
}

async function seedBuddy(client, now) {
  const pet = DEMO_IDS.buddyPet;
  const base = { petId: pet, userId: OWNER };

  // Apoquel: twice daily for 10 days; older doses recorded; yesterday 18:00
  // and today 08:00 left open → "1 dose not recorded" + Overdue/Due today.
  const apoquel = { entryId: DEMO_IDS.coBuddyApoquel, userId: OWNER };
  await createSeedCareItem(client, {
    ...base, id: apoquel.entryId, name: 'Apoquel', careFamily: 'medication', dosage: '16 mg',
    frequency: 'daily', times: ['08:00', '18:00'], firstDate: dayFrom(now, -10),
  }, clockAt(now, -10, '07:00'));
  for (let offset = -10; offset <= -2; offset += 1) {
    await recordDay(client, apoquel, dayFrom(now, offset), clockAt(now, offset, '20:00'));
  }
  await recordDay(client, apoquel, dayFrom(now, -1), clockAt(now, -1, '09:00'), { onlyTimes: ['08:00'] });

  // Heart tablet: daily 09:00, remembered choice "Skip the next date".
  const heart = { entryId: DEMO_IDS.coBuddyHeartTablet, userId: OWNER };
  await createSeedCareItem(client, {
    ...base, id: heart.entryId, name: 'Heart tablet', careFamily: 'medication', dosage: '1 tablet',
    frequency: 'daily', times: ['09:00'], firstDate: dayFrom(now, -3), lateChoice: 'skip_next',
  }, clockAt(now, -3, '07:00'));
  for (let offset = -3; offset <= -1; offset += 1) {
    await recordDay(client, heart, dayFrom(now, offset), clockAt(now, offset, '09:30'));
  }

  // NexGard: monthly, after it's done, due in 3 days → Due soon.
  await createSeedCareItem(client, {
    ...base, id: DEMO_IDS.coBuddyNexgard, name: 'NexGard', careFamily: 'parasite_prevention',
    frequency: 'monthly', firstDate: dayFrom(now, 3), remindDaysBefore: 3,
  }, clockAt(now, -27, '09:00'));

  // DHPP: first dose done 20 days ago, booster planned in 10 days, then yearly.
  const dhpp = { entryId: DEMO_IDS.coBuddyDhpp, userId: OWNER };
  await createSeedCareItem(client, {
    ...base, id: dhpp.entryId, name: 'DHPP vaccine', careFamily: 'vaccination', frequency: 'yearly',
    firstDate: dayFrom(now, -20), plannedDates: [dayFrom(now, 10)], remindDaysBefore: 7,
  }, clockAt(now, -21, '09:00'));
  await completeEarliest(client, dhpp, clockAt(now, -20, '11:00'));

  // Rabies: yearly, due in 200 days → Upcoming.
  await createSeedCareItem(client, {
    ...base, id: DEMO_IDS.coBuddyRabies, name: 'Rabies vaccine', careFamily: 'vaccination',
    frequency: 'yearly', firstDate: dayFrom(now, 200), remindDaysBefore: 14,
  }, clockAt(now, -165, '09:00'));

  // Wellness review: yearly, overdue by 5 days → Today, Overdue first.
  await createSeedCareItem(client, {
    ...base, id: DEMO_IDS.buddyOverduePreventive, name: 'Wellness review', careFamily: 'wellness_review',
    frequency: 'yearly', firstDate: dayFrom(now, -5), setting: 'vet', remindDaysBefore: 7,
  }, clockAt(now, -40, '09:00'));

  // Dental chew: daily, after it's done, any time → "Anytime" / "Today's list".
  const chew = { entryId: DEMO_IDS.coBuddyDentalChew, userId: OWNER };
  await createSeedCareItem(client, {
    ...base, id: chew.entryId, name: 'Dental chew', careFamily: 'dental', frequency: 'daily',
    firstDate: dayFrom(now, -1),
  }, clockAt(now, -2, '09:00'));
  await completeEarliest(client, chew, clockAt(now, -1, '19:00'));

  // Grooming: every 6 weeks, paused (Resume asks the date).
  const groom = { entryId: DEMO_IDS.coBuddyGrooming, userId: OWNER };
  await createSeedCareItem(client, {
    ...base, id: groom.entryId, name: 'Grooming', careFamily: 'grooming', frequency: 'weekly',
    interval: 6, firstDate: dayFrom(now, 4),
  }, clockAt(now, -38, '09:00'));
  await postpone(client, groom, null, clockAt(now, -3, '10:00'));

  for (const entryId of [apoquel.entryId, heart.entryId, dhpp.entryId, chew.entryId]) {
    await catchUp(client, { entryId, userId: OWNER }, now);
  }
}

async function seedWhiskers(client, now) {
  const pet = DEMO_IDS.whiskersPet;
  const base = { petId: pet, userId: OWNER };

  // Methimazole: 08:00 and 20:00; T−5 recorded, T−4 08:00 recorded and
  // 20:00 auto-closed as Not recorded; T−3 … T−1 open → "6 doses not recorded".
  const meth = { entryId: DEMO_IDS.coWhiskersMethimazole, userId: OWNER };
  await createSeedCareItem(client, {
    ...base, id: meth.entryId, name: 'Methimazole', careFamily: 'medication', dosage: '2.5 mg',
    frequency: 'daily', times: ['08:00', '20:00'], firstDate: dayFrom(now, -5),
  }, clockAt(now, -5, '07:00'));
  await recordDay(client, meth, dayFrom(now, -5), clockAt(now, -5, '21:00'));
  await recordDay(client, meth, dayFrom(now, -4), clockAt(now, -4, '09:00'), { onlyTimes: ['08:00'] });
  await catchUp(client, meth, now);

  // Flea treatment: monthly at 19:00, due today → Evening group.
  await createSeedCareItem(client, {
    ...base, id: DEMO_IDS.coWhiskersFlea, name: 'Flea treatment', careFamily: 'parasite_prevention',
    frequency: 'monthly', times: ['19:00'], firstDate: now.todayIso,
  }, clockAt(now, -30, '09:00'));

  // Nail trim: every 3 weeks, due tomorrow → Due soon.
  await createSeedCareItem(client, {
    ...base, id: DEMO_IDS.coWhiskersNailTrim, name: 'Nail trim', careFamily: 'nail_care',
    frequency: 'weekly', interval: 3, firstDate: dayFrom(now, 1),
  }, clockAt(now, -20, '09:00'));

  // Vaccination: yearly, due in 90 days → Upcoming.
  await createSeedCareItem(client, {
    ...base, id: DEMO_IDS.coWhiskersVaccination, name: 'Cat vaccination', careFamily: 'vaccination',
    frequency: 'yearly', firstDate: dayFrom(now, 90), setting: 'vet', remindDaysBefore: 14,
  }, clockAt(now, -275, '09:00'));

  // Monthly weigh-in: Fixed schedule set explicitly (category default is After
  // it's done), anchored on the 31st → next dates clamp to month ends.
  const anchor = lastThirtyFirst(now.todayIso);
  const weigh = { entryId: DEMO_IDS.coWhiskersWeighIn, userId: OWNER };
  await createSeedCareItem(client, {
    ...base, id: weigh.entryId, name: 'Monthly weigh-in', careFamily: 'weight_monitoring',
    frequency: 'monthly', scheduleType: 'from_due_date', firstDate: anchor,
  }, { todayIso: anchor, nowTimeIso: '08:00', timeZone: now.timeZone });
  const done = await completeEarliest(client, weigh, { todayIso: anchor, nowTimeIso: '10:00', timeZone: now.timeZone });
  if (done?.occurrence) {
    await client.query(
      `INSERT INTO weight_entries (id, pet_id, user_id, weight, unit, date, notes, measurement_source, health_occurrence_id)
       VALUES ($1, $2, $3, 4.3, 'kg', $4, 'Monthly weigh-in', 'guardian', $5)
       ON CONFLICT (id) DO UPDATE SET date = EXCLUDED.date, health_occurrence_id = EXCLUDED.health_occurrence_id`,
      [DEMO_IDS.coWhiskersWeighInWeight, pet, OWNER, anchor, done.occurrence.id],
    );
  }
  await catchUp(client, weigh, now);

  // Vet visit: recorded last week (no schedule) → History only.
  await createSeedCareItem(client, {
    ...base, id: DEMO_IDS.whiskersVetVisit, name: 'Vet visit', careFamily: 'wellness_review',
    completedOn: dayFrom(now, -7), setting: 'vet',
  }, now);
}

export async function seedCareOccurrences(client) {
  await client.query(
    'UPDATE pets SET home_timezone = $1 WHERE id = ANY($2::uuid[])',
    [SEED_PET_TIMEZONE, [DEMO_IDS.buddyPet, DEMO_IDS.whiskersPet]],
  );
  const now = seedNow(SEED_PET_TIMEZONE);
  await seedBuddy(client, now);
  await seedWhiskers(client, now);
  console.log(`seed: care-occurrences ready (${now.todayIso} ${now.nowTimeIso} ${now.timeZone})`);
}
