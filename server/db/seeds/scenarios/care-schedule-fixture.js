import { DEMO_IDS } from '../demo-constants.js';
import {
  catchUp,
  clockAt,
  createSeedCareItem,
  recordDay,
  seedNow,
} from '../helpers/care-commands.js';

/**
 * Care Schedule Management fixtures used by the away-planning dataset:
 * a twice-daily weekly course (multi-time rhythm across an absence) and a
 * daily After-it's-done item (estimated dates). Built through the care
 * commands; the old "far-future, no occurrence" blind spot no longer exists
 * (D-CSM-019). Other CSM edge cases are covered by care-occurrences.js and
 * server/test/db/careOccurrences.*.integration.test.js.
 */
export async function seedCareScheduleFixture(client) {
  const now = seedNow();
  const owner = { userId: DEMO_IDS.alice };

  const course = { entryId: DEMO_IDS.csmWeeklyCourse, userId: DEMO_IDS.alice };
  await createSeedCareItem(client, {
    id: course.entryId,
    petId: DEMO_IDS.buddyPet,
    ...owner,
    name: 'Weekly antibiotic course',
    careFamily: 'medication',
    dosage: '1 capsule',
    frequency: 'weekly',
    times: ['08:00', '20:00'],
    firstDate: now.todayIso,
    remindDaysBefore: 3,
    notes: 'Twice on the day, once a week — multi-time rhythm across an absence',
  }, clockAt(now, 0, '07:00'));
  await recordDay(client, course, now.todayIso, clockAt(now, 0, '08:15'), { onlyTimes: ['08:00'] });
  await catchUp(client, course, now);

  await createSeedCareItem(client, {
    id: DEMO_IDS.csmFromCompletionDaily,
    petId: DEMO_IDS.buddyPet,
    ...owner,
    name: 'Morning joint supplement',
    careFamily: 'medication',
    scheduleType: 'from_completion',
    dosage: '1 tablet',
    frequency: 'daily',
    firstDate: now.todayIso,
    remindDaysBefore: 3,
    notes: 'After it\'s done, set explicitly — estimated dates in away plans',
  }, clockAt(now, -1, '09:00'));

  console.log('seed: care-schedule-fixture ready (multi-time weekly course, daily after-it\'s-done)');
}
