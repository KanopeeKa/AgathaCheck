/**
 * Health entry create and update use cases extracted from CRUD routes.
 */

import { v4 as uuidv4 } from 'uuid';
import { assertAtLeastOneDate } from '../recurrenceHelper.js';
import { dateToIsoDate, normalizeCalendarDateInput } from '../calendarDate.js';
import { userCanManageHealthEntry } from '../petAccess.js';
import { hasPetCapability, PET_CAPABILITIES } from '../petCapabilityPolicy.js';
import {
  rejectClientTypeField,
  resolveClassificationForWrite,
} from '../care/taxonomy/classification.js';
import { recordPetActivityForPet } from '../petActivity.js';
import { parseScheduleTimesInput } from '../care/item/index.js';
import {
  createInitialOccurrences,
  reconcileScheduleEdit,
  runCareCommand,
} from '../care/occurrence/index.js';
import {
  applyLateCompletionChoice,
  parseLateCompletionChoice,
} from '../care/item/index.js';
import { validateScheduleShape } from './scheduleValidation.js';
import {
  SCHEDULE_POLICY_VERSION,
  resolveRecurrenceAnchorForWrite,
} from '../care/schedule/index.js';
import { resolveCareBlocksForWrite } from '../care/categoryBlocks/index.js';
import {
  validateCareFamilyForWrite,
  validateCareSourceForWrite,
  resolveEntryProviderForWrite,
} from './healthEntryWriteSupport.js';

export async function createHealthEntry(pool, userId, body, req) {
          const data = body;
      const id = data.id || uuidv4();
      const petId = data.pet_id || data.petId;
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_EDIT))) {
        return { status: 403, error: 'Forbidden' };
      }
      const startDate = normalizeCalendarDateInput(data.start_date || data.startDate);
      const nextDueDate = normalizeCalendarDateInput(data.next_due_date || data.nextDueDate);
      const completedOn = normalizeCalendarDateInput(data.completed_on || data.completedOn);
      const repeatEndDate = normalizeCalendarDateInput(data.repeat_end_date || data.repeatEndDate);
      const healthIssueId = data.health_issue_id || data.healthIssueId || null;
      try {
        assertAtLeastOneDate(nextDueDate, completedOn);
      } catch (e) {
        return { status: 400, error: e.message };
      }
      const typeRejection = rejectClientTypeField(data);
      if (!typeRejection.ok) {
        return { status: 400, error: typeRejection.error };
      }
      const scheduleTimes = parseScheduleTimesInput(data);
      const frequency = data.frequency || 'once';
      const careFamilyValidation = validateCareFamilyForWrite(
        data.care_family || data.careFamily,
        { requiredOnCreate: true },
      );
      if (!careFamilyValidation.ok) {
        return { status: 400, error: careFamilyValidation.error };
      }
      const careSourceValidation = validateCareSourceForWrite(
        data.care_source || data.careSource,
      );
      if (!careSourceValidation.ok) {
        return { status: 400, error: careSourceValidation.error };
      }
      const careFamily = careFamilyValidation.value;
      const classification = resolveClassificationForWrite({
        data,
        careFamily,
        frequency,
        completedOn,
        nextDueDate,
      });
      if (!classification.ok) {
        return { status: 400, error: classification.error };
      }
      const {
        care_setting: careSetting,
        care_planning: carePlanning,
        care_importance: careImportance,
        importance_overridden: importanceOverridden,
        type: derivedType,
        remind_days_before: remindDaysBefore,
      } = classification.value;
      let recurrenceAnchor;
      try {
        recurrenceAnchor = resolveRecurrenceAnchorForWrite({
          careFamily,
          explicitAnchor: data.recurrence_anchor ?? data.recurrenceAnchor,
        });
      } catch (e) {
        return { status: 400, error: e.message };
      }
      const scheduleShape = validateScheduleShape({
        carePlanning,
        completedOn,
        recurrenceAnchor,
        frequency,
        scheduleTimes,
        plannedDates: data.planned_dates ?? data.plannedDates,
      });
      if (!scheduleShape.ok) {
        return { status: 400, error: scheduleShape.error, code: scheduleShape.code };
      }
      const providerResolved = await resolveEntryProviderForWrite(pool, userId, petId, data);
      if (providerResolved.error) {
        return { status: 400, error: providerResolved.error, ...(providerResolved.code ? { code: providerResolved.code } : {}) };
      }
      const { providerContactId, providerTypedName } = providerResolved;
      const { careBlocks, dosage: resolvedDosage } = resolveCareBlocksForWrite({
        data,
        careFamily,
      });
      const lateChoice = parseLateCompletionChoice(data);
      if (lateChoice.error) return { status: 400, error: lateChoice.error };
      const insertRow = (db) => db.query(
        `INSERT INTO health_entries (id, pet_id, user_id, name, type, dosage, frequency, frequency_days, frequency_interval, start_date, next_due_date, completed_on, recurrence_anchor, repeat_end_date, notes, health_issue_id, remind_days_before, schedule_times, status, care_family, care_setting, care_planning, care_importance, importance_overridden, care_source, schedule_policy_version, provider_contact_id, provider_typed_name, care_blocks)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29) RETURNING *`,
        [
          id, petId, userId,
          data.name || '',
          derivedType,
          resolvedDosage,
          frequency,
          data.frequency_days || data.frequencyDays || null,
          data.frequency_interval || data.frequencyInterval || 1,
          startDate, nextDueDate, completedOn,
          recurrenceAnchor, repeatEndDate,
          data.notes || '',
          healthIssueId,
          remindDaysBefore,
          scheduleTimes == null ? null : JSON.stringify(scheduleTimes),
          completedOn ? 'completed' : (data.status || 'active'),
          careFamily,
          careSetting,
          carePlanning,
          careImportance,
          importanceOverridden,
          careSourceValidation.value,
          SCHEDULE_POLICY_VERSION,
          providerContactId,
          providerTypedName,
          JSON.stringify(careBlocks),
        ]
      );
      const insertEntry = async (db) => {
        const inserted = await insertRow(db);
        await applyLateCompletionChoice(db, inserted.rows[0], lateChoice);
        return inserted;
      };
      const out = await runCareCommand(pool, {
        entryId: id,
        userId,
        req,
        beforeLock: insertEntry,
      }, (ctx) => createInitialOccurrences(ctx, {
        firstDate: nextDueDate || startDate || null,
        plannedDates: scheduleShape.plannedDates,
      }));
      const entry = out.entry;
      entry.pet_name = null;
      recordPetActivityForPet(pool, {
        petId,
        actorUserId: userId,
        eventType: 'health_log',
        metadata: { action: 'create', entry_type: derivedType },
      });
      return { status: 201, entry, openRows: out.openOccurrences, asOf: out.asOf };
}

export async function updateHealthEntry(pool, userId, entryId, body, req) {
          if (!(await userCanManageHealthEntry(pool, entryId, userId))) {
        return { status: 404, error: 'Entry not found' };
      }
      const data = body;
      const startDate = normalizeCalendarDateInput(data.start_date || data.startDate);
      const nextDueDate = normalizeCalendarDateInput(data.next_due_date || data.nextDueDate);
      const completedOn = normalizeCalendarDateInput(data.completed_on || data.completedOn);
      const repeatEndDate = normalizeCalendarDateInput(data.repeat_end_date || data.repeatEndDate);
      const healthIssueId = data.health_issue_id || data.healthIssueId || null;
      try {
        assertAtLeastOneDate(nextDueDate, completedOn);
      } catch (e) {
        return { status: 400, error: e.message };
      }
      const typeRejection = rejectClientTypeField(data);
      if (!typeRejection.ok) {
        return { status: 400, error: typeRejection.error };
      }
      const lateChoice = parseLateCompletionChoice(data);
      if (lateChoice.error) return { status: 400, error: lateChoice.error };
      const existingResult = await pool.query(
        'SELECT * FROM health_entries WHERE id = $1',
        [entryId],
      );
      if (existingResult.rows.length === 0) {
        return { status: 404, error: 'Entry not found' };
      }
      const existing = existingResult.rows[0];
      const frequency = data.frequency || 'once';
      const isRecurring = frequency && frequency !== 'once';
      const careFamilyInput =
        data.care_family || data.careFamily || (isRecurring ? existing.care_family : null);
      const careFamilyValidation = validateCareFamilyForWrite(
        careFamilyInput,
        { recurring: isRecurring },
      );
      if (!careFamilyValidation.ok) {
        return { status: 400, error: careFamilyValidation.error };
      }
      const careSourceValidation = validateCareSourceForWrite(
        data.care_source || data.careSource,
      );
      if (!careSourceValidation.ok) {
        return { status: 400, error: careSourceValidation.error };
      }
      const careFamily = careFamilyValidation.value;
      const classification = resolveClassificationForWrite({
        data,
        careFamily,
        frequency,
        completedOn,
        nextDueDate,
        existing,
      });
      if (!classification.ok) {
        return { status: 400, error: classification.error };
      }
      const {
        care_setting: careSetting,
        care_planning: carePlanning,
        care_importance: careImportance,
        importance_overridden: importanceOverridden,
        type: derivedType,
        remind_days_before: remindDaysBefore,
      } = classification.value;
      const careSource =
        careSourceValidation.value || existing.care_source || 'guardian_defined';
      const explicitAnchorProvided = (
        data.recurrence_anchor !== undefined
        || data.recurrenceAnchor !== undefined
      );
      const careFamilyChanged = careFamily !== existing.care_family;
      let recurrenceAnchor;
      try {
        if (explicitAnchorProvided) {
          recurrenceAnchor = resolveRecurrenceAnchorForWrite({
            careFamily,
            explicitAnchor: data.recurrence_anchor ?? data.recurrenceAnchor,
          });
        } else if (!careFamilyChanged && existing.recurrence_anchor) {
          recurrenceAnchor = existing.recurrence_anchor;
        } else {
          recurrenceAnchor = resolveRecurrenceAnchorForWrite({
            careFamily,
            explicitAnchor: null,
          });
        }
      } catch (e) {
        return { status: 400, error: e.message };
      }
      const providerResolved = await resolveEntryProviderForWrite(
        pool,
        userId,
        existing.pet_id,
        data,
        existing,
      );
      if (providerResolved.error) {
        return { status: 400, error: providerResolved.error, ...(providerResolved.code ? { code: providerResolved.code } : {}) };
      }
      const { providerContactId, providerTypedName } = providerResolved;
      const { careBlocks, dosage: resolvedDosage } = resolveCareBlocksForWrite({
        data,
        careFamily,
        existing,
        careFamilyChanged,
      });
      const parsedTimes = parseScheduleTimesInput(data);
      const scheduleTimes = parsedTimes === undefined ? existing.schedule_times : parsedTimes;
      const scheduleShape = validateScheduleShape({
        carePlanning,
        completedOn,
        recurrenceAnchor,
        frequency,
        scheduleTimes,
        existingCompletedOn: dateToIsoDate(existing.completed_on),
      });
      if (!scheduleShape.ok) {
        return { status: 400, error: scheduleShape.error, code: scheduleShape.code };
      }
      const existingStart = dateToIsoDate(existing.start_date);
      if (startDate && existingStart && startDate !== existingStart) {
        const closed = await pool.query(
          `SELECT 1 FROM health_occurrences
           WHERE health_entry_id = $1 AND status IN ('completed', 'skipped') LIMIT 1`,
          [entryId],
        );
        if (closed.rows.length > 0) {
          return {
            status: 400,
            error: 'The start date cannot change once care has been recorded',
            code: 'start_date_locked',
          };
        }
      }
      const status = carePlanning === 'unplanned'
        ? 'completed'
        : (existing.status || 'active');
      const out = await runCareCommand(pool, { entryId: entryId, userId, req }, async (ctx) => {
        const updated = await ctx.db.query(
          `UPDATE health_entries SET name = $1, type = $2, dosage = $3, frequency = $4, frequency_days = $5,
            frequency_interval = $6, start_date = $7, completed_on = $8,
            recurrence_anchor = $9, repeat_end_date = $10, notes = $11,
            health_issue_id = $12, remind_days_before = $13, status = $14,
            care_family = $15, care_setting = $16, care_planning = $17, care_importance = $18,
            importance_overridden = $19, care_source = $20, schedule_policy_version = $21,
            provider_contact_id = $22, provider_typed_name = $23, care_blocks = $24,
            schedule_times = $25::jsonb, updated_at = NOW()
           WHERE id = $26 RETURNING *`,
          [
            data.name || '',
            derivedType,
            resolvedDosage,
            frequency,
            data.frequency_days || data.frequencyDays || null,
            data.frequency_interval || data.frequencyInterval || 1,
            startDate || existingStart, completedOn,
            recurrenceAnchor, repeatEndDate,
            data.notes || '',
            healthIssueId,
            remindDaysBefore,
            status,
            careFamily,
            careSetting,
            carePlanning,
            careImportance,
            importanceOverridden,
            careSource,
            SCHEDULE_POLICY_VERSION,
            providerContactId,
            providerTypedName,
            JSON.stringify(careBlocks),
            scheduleTimes == null ? null : JSON.stringify(scheduleTimes),
            entryId,
          ]
        );
        const edited = await applyLateCompletionChoice(ctx.db, updated.rows[0], lateChoice);
        return reconcileScheduleEdit({ ...ctx, entry: edited }, {
          before: ctx.entry,
          requestedNextDate: nextDueDate,
        });
      });
      if (!out) return { status: 404, error: 'Entry not found' };
      const entry = out.entry;
      entry.pet_name = null;
      recordPetActivityForPet(pool, {
        petId: entry.pet_id,
        actorUserId: userId,
        eventType: 'health_log',
        metadata: { action: 'update', entry_type: derivedType },
      });
      return { entry, openRows: out.openOccurrences, asOf: out.asOf };
}

export async function deleteHealthEntry(pool, userId, entryId) {
  if (!(await userCanManageHealthEntry(pool, entryId, userId))) {
    return { status: 404, error: 'Entry not found' };
  }
  await pool.query('DELETE FROM health_entries WHERE id = $1', [entryId]);
  return { deleted: true };
}
