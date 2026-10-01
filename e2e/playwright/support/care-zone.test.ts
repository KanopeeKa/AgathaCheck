import assert from 'node:assert/strict';
import { test } from 'node:test';
import { zoneAtMidAfternoon } from './care-zone';

function localHour(timeZone: string, now: Date): number {
  return Number(new Intl.DateTimeFormat('en-GB', { timeZone, hour: '2-digit', hourCycle: 'h23' }).format(now));
}

function localDay(timeZone: string, now: Date): string {
  return new Intl.DateTimeFormat('en-CA', { timeZone, year: 'numeric', month: '2-digit', day: '2-digit' }).format(now);
}

test('every UTC hour maps to a zone where it is 15:xx, with that zone\'s day', () => {
  for (let hour = 0; hour < 24; hour += 1) {
    const now = new Date(Date.UTC(2026, 9, 1, hour, 37));
    const { timeZone, day } = zoneAtMidAfternoon(now);
    assert.equal(localHour(timeZone, now), 15, `${timeZone} at ${hour}:37 UTC`);
    assert.equal(day, localDay(timeZone, now), `${timeZone} day at ${hour}:37 UTC`);
  }
});

test('POSIX sign: UTC+3 is Etc/GMT-3', () => {
  assert.equal(zoneAtMidAfternoon(new Date(Date.UTC(2026, 9, 1, 12, 0))).timeZone, 'Etc/GMT-3');
  assert.equal(zoneAtMidAfternoon(new Date(Date.UTC(2026, 9, 1, 15, 0))).timeZone, 'Etc/UTC');
});
