/**
 * Care item API helpers (care-next-occurrence-c1a7 §11.5). Care is seeded
 * through the API only — never SQL on health_occurrences — so the same
 * helpers work on localhost and live UAT. `withCareClock` pins "now" with
 * the X-Care-As-Of test clock (localhost only; ignored on UAT/production).
 */
import type { Page } from '@playwright/test';
import { apiFetch } from './api-fetch';
import { setPageCareClock } from './care-clock';

const API_PREFIX = process.env.E2E_API_PREFIX ?? '/backend/api';
const CARE_CLOCK_HEADER = 'X-Care-As-Of';

let careClock: string | null = null;

/** Pin care "now" (`YYYY-MM-DDTHH:MM`, pet home time) for API calls and, if given, the page. */
export async function withCareClock(isoLocal: string | null, page?: Page): Promise<void> {
  careClock = isoLocal;
  if (page) {
    await setPageCareClock(page, isoLocal);
  }
}

/** Create a pet whose home time zone is `timeZone` (care "today" follows it). */
export async function createPetInZone(
  baseURL: string,
  token: string,
  name: string,
  timeZone: string,
): Promise<{ id: string; name: string }> {
  const res = await apiFetch(`${baseURL.replace(/\/$/, '')}${API_PREFIX}/pets`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify({ name, species: 'Dog', home_timezone: timeZone }),
  });
  if (!res.ok) throw new Error(`createPetInZone failed (${res.status}): ${await res.text()}`);
  return res.json<{ id: string; name: string }>();
}

export type OccurrenceStatus = 'coming_up' | 'due' | 'overdue' | 'not_recorded';

export interface OpenOccurrence {
  id: string;
  scheduled_date: string;
  scheduled_time: string | null;
  status: OccurrenceStatus;
  origin: 'schedule' | 'computed' | 'planned';
}

export interface CareItem {
  id: string;
  name: string;
  status: string;
  recurrence_anchor: 'from_due_date' | 'from_completion';
  next_due_date: string | null;
  open_occurrences: OpenOccurrence[];
  as_of: { date: string; time: string; timezone: string };
  estimated_next: { date: string; basis: string } | null;
  late_completion_choice: string | null;
  paused_until: string | null;
  resume_default_date: string | null;
}

export interface CareCommandResult {
  status: number;
  body: {
    entry?: CareItem;
    next_due_date?: string | null;
    undo_token?: string | null;
    code?: string;
    options?: string[];
    shift?: { days?: number; minutes?: number };
    [key: string]: unknown;
  };
}

function url(path: string, baseURL: string): string {
  return `${baseURL.replace(/\/$/, '')}${API_PREFIX}/health-entries${path}`;
}

async function send(
  baseURL: string,
  token: string,
  method: string,
  path: string,
  body?: unknown,
): Promise<CareCommandResult> {
  const headers: Record<string, string> = { Authorization: `Bearer ${token}` };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (careClock) headers[CARE_CLOCK_HEADER] = careClock;
  const res = await apiFetch(url(path, baseURL), {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  return { status: res.status, body: text ? JSON.parse(text) : {} };
}

function expectOk(label: string, result: CareCommandResult): CareCommandResult {
  if (result.status >= 400) {
    throw new Error(`${label} failed (${result.status}): ${JSON.stringify(result.body)}`);
  }
  return result;
}

export async function createCareItem(
  baseURL: string,
  token: string,
  petId: string,
  options: {
    name: string;
    careFamily: string;
    frequency?: string;
    interval?: number;
    dueDate?: string;
    completedOn?: string;
    times?: string[];
    scheduleType?: 'from_due_date' | 'from_completion';
    plannedDates?: string[];
    dosage?: string;
    remindDaysBefore?: number;
  },
): Promise<CareItem> {
  const body: Record<string, unknown> = {
    pet_id: petId,
    name: options.name,
    care_family: options.careFamily,
    frequency: options.completedOn ? 'once' : (options.frequency ?? 'once'),
    frequency_interval: options.interval ?? 1,
    dosage: options.dosage ?? '',
  };
  if (options.completedOn) {
    body.care_planning = 'unplanned';
    body.completed_on = options.completedOn;
  } else {
    body.next_due_date = options.dueDate ?? new Date().toISOString().slice(0, 10);
  }
  if (options.times) body.schedule_times = options.times;
  if (options.scheduleType) body.recurrence_anchor = options.scheduleType;
  if (options.plannedDates) body.planned_dates = options.plannedDates;
  if (options.remindDaysBefore != null) body.remind_days_before = options.remindDaysBefore;
  const res = expectOk('createCareItem', await send(baseURL, token, 'POST', '', body));
  return res.body as unknown as CareItem;
}

export async function getCareItem(baseURL: string, token: string, entryId: string): Promise<CareItem> {
  const res = expectOk('getCareItem', await send(baseURL, token, 'GET', `/${entryId}`));
  return res.body as unknown as CareItem;
}

export interface HealthEntryOccurrenceRow {
  id: string;
  health_entry_id: string;
  scheduled_date: string;
  scheduled_time: string | null;
  status: string;
  missed?: boolean;
}

/** Occurrence rows for an entry — respects [withCareClock] when set. */
export async function listHealthEntryOccurrences(
  baseURL: string,
  token: string,
  entryId: string,
  options: { status?: 'open' | 'past' } = {},
): Promise<HealthEntryOccurrenceRow[]> {
  const qs = options.status ? `?status=${encodeURIComponent(options.status)}` : '';
  const res = expectOk(
    'listHealthEntryOccurrences',
    await send(baseURL, token, 'GET', `/${entryId}/occurrences${qs}`),
  );
  return res.body as HealthEntryOccurrenceRow[];
}

/** Read the actual away-window projection, including materialised occurrence ids. */
export async function getCarePeriodCoverage(
  baseURL: string,
  token: string,
  petId: string,
  startsOn: string,
  endsOn: string,
): Promise<{
  items: Array<{
    health_entry_id: string;
    occurrence_id: string | null;
    scheduled_date: string;
    source: string;
  }>;
  planned_care_items: Array<{
    health_entry_id: string;
    in_window?: { first_date: string; last_date: string; count: number; date_basis: string } | null;
  }>;
}> {
  const query = new URLSearchParams({ starts_on: startsOn, ends_on: endsOn });
  const res = await apiFetch(
    `${baseURL.replace(/\/$/, '')}${API_PREFIX}/pets/${petId}/care-period-coverage?${query}`,
    { headers: { Authorization: `Bearer ${token}`, ...(careClock ? { [CARE_CLOCK_HEADER]: careClock } : {}) } },
  );
  const text = await res.text();
  if (!res.ok) throw new Error(`getCarePeriodCoverage failed (${res.status}): ${text}`);
  return JSON.parse(text);
}

/** Trigger a reminder scan with the same pinned care clock as the care commands. */
export async function checkCareReminders(baseURL: string, token: string): Promise<void> {
  const res = await apiFetch(`${baseURL.replace(/\/$/, '')}${API_PREFIX}/notifications/check-due`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...(careClock ? { [CARE_CLOCK_HEADER]: careClock } : {}),
    },
    body: JSON.stringify({}),
  });
  if (!res.ok) throw new Error(`checkCareReminders failed (${res.status}): ${await res.text()}`);
}

/** Complete one open date; returns the raw result so tests can assert a 409. */
export async function completeOccurrence(
  baseURL: string,
  token: string,
  entryId: string,
  occurrenceId: string,
  options: { completedOn?: string; nextChoice?: string; rememberChoice?: boolean; earlierChoice?: string } = {},
): Promise<CareCommandResult> {
  return send(baseURL, token, 'POST', `/${entryId}/occurrences/${occurrenceId}/complete`, {
    completed_on: options.completedOn,
    next_choice: options.nextChoice,
    remember_choice: options.rememberChoice,
    earlier_choice: options.earlierChoice,
  });
}

/** Complete the earliest open date (Keep when a choice is needed). */
export async function completeNextOccurrence(
  baseURL: string,
  token: string,
  entryId: string,
  options: { completedOn?: string } = {},
): Promise<CareItem> {
  const item = await getCareItem(baseURL, token, entryId);
  const first = item.open_occurrences[0];
  if (!first) throw new Error(`completeNextOccurrence: ${entryId} has no open date`);
  const res = expectOk('completeNextOccurrence', await completeOccurrence(baseURL, token, entryId, first.id, {
    ...options,
    nextChoice: 'keep',
    earlierChoice: 'keep',
  }));
  return res.body.entry as CareItem;
}

export async function getOccurrence(
  baseURL: string,
  token: string,
  entryId: string,
  occurrenceId: string,
): Promise<Record<string, unknown>> {
  const res = expectOk(
    'getOccurrence',
    await send(baseURL, token, 'GET', `/${entryId}/occurrences/${occurrenceId}`),
  );
  return res.body as Record<string, unknown>;
}

export async function patchOccurrence(
  baseURL: string,
  token: string,
  entryId: string,
  occurrenceId: string,
  body: { completed_on: string },
): Promise<Record<string, unknown>> {
  const res = expectOk(
    'patchOccurrence',
    await send(baseURL, token, 'PATCH', `/${entryId}/occurrences/${occurrenceId}`, body),
  );
  return res.body as Record<string, unknown>;
}

export async function skipOccurrence(baseURL: string, token: string, entryId: string, occurrenceId: string) {
  return expectOk('skipOccurrence', await send(baseURL, token, 'POST', `/${entryId}/occurrences/${occurrenceId}/skip`, {}));
}

export async function recordEarlierDoses(
  baseURL: string,
  token: string,
  entryId: string,
  given: string[],
  notGiven: string[] = [],
) {
  return expectOk('recordEarlierDoses', await send(baseURL, token, 'POST', `/${entryId}/occurrences/resolve-stack`, {
    given,
    not_given: notGiven,
  }));
}

export async function planAnotherDate(baseURL: string, token: string, entryId: string, date: string, time?: string) {
  return expectOk('planAnotherDate', await send(baseURL, token, 'POST', `/${entryId}/occurrences`, {
    scheduled_date: date,
    scheduled_time: time,
  }));
}

export async function changeDate(
  baseURL: string,
  token: string,
  entryId: string,
  occurrenceId: string,
  date: string,
  scope: 'this' | 'following' = 'this',
) {
  return expectOk('changeDate', await send(baseURL, token, 'POST', `/${entryId}/occurrences/${occurrenceId}/reschedule`, {
    scheduled_date: date,
    scope,
  }));
}

export async function postpone(
  baseURL: string,
  token: string,
  entryId: string,
  until: string | null,
  options: { reason?: 'pause' | 'absence' | 'manual'; absenceId?: string } = {},
) {
  return expectOk('postpone', await send(baseURL, token, 'POST', `/${entryId}/postpone`, {
    until,
    reason: options.reason,
    absence_id: options.absenceId,
  }));
}

export async function resume(baseURL: string, token: string, entryId: string, date?: string) {
  return expectOk('resume', await send(baseURL, token, 'POST', `/${entryId}/resume`, date ? { date } : {}));
}

export async function undoLast(baseURL: string, token: string, entryId: string, undoToken?: string) {
  return expectOk('undoLast', await send(baseURL, token, 'POST', `/${entryId}/schedule/undo`, {
    undo_token: undoToken,
  }));
}

export interface HealthEntryAbsenceContext {
  health_entry_id: string;
  pet_id: string;
  absences: Array<{
    planned_absence_id: string;
    starts_on: string;
    ends_on: string;
    planned_care?: {
      planned_dates?: Array<{
        scheduled_date: string;
        occurrence_id: string | null;
      }>;
      looked_after_by?: {
        carer_kind: string;
        carer_name: string | null;
      };
    };
  }>;
}

export async function getHealthEntryAbsenceContext(
  baseURL: string,
  token: string,
  entryId: string,
): Promise<HealthEntryAbsenceContext> {
  const res = await apiFetch(
    `${baseURL.replace(/\/$/, '')}${API_PREFIX}/health-entries/${entryId}/absence-context`,
    {
      headers: { Authorization: `Bearer ${token}` },
    },
  );
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`getHealthEntryAbsenceContext failed (${res.status}): ${text}`);
  }
  return JSON.parse(text) as HealthEntryAbsenceContext;
}
