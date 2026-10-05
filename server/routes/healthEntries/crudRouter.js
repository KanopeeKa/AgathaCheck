import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { assertAtLeastOneDate } from '../../lib/recurrenceHelper.js';
import { dateToIsoDate, normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import {
  accessiblePetSql,
  userCanManageHealthEntry,
} from '../../lib/petAccess.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import {
  rejectClientTypeField,
  resolveClassificationForWrite,
} from '../../lib/care/taxonomy/classification.js';
import {
  extractUserId,
  healthEntryToMap,
  csvCell,
  validateCareFamilyForWrite,
  validateCareSourceForWrite,
  resolveEntryProviderForWrite,
} from './shared.js';
import { recordPetActivityForPet } from '../../lib/petActivity.js';
import { parseScheduleTimesInput } from '../../lib/care/item/index.js';
import {
  createInitialOccurrences,
  reconcileScheduleEdit,
  runCareCommand,
  sendCareCommandError,
} from '../../lib/care/occurrence/index.js';
import {
  applyLateCompletionChoice,
  careItemWire,
  careItemsWire,
  parseLateCompletionChoice,
} from '../../lib/care/item/index.js';
import { validateScheduleShape } from './scheduleValidation.js';
import {
  SCHEDULE_POLICY_VERSION,
  resolveRecurrenceAnchorForWrite,
} from '../../lib/care/schedule/index.js';
import { resolveCareBlocksForWrite } from '../../lib/care/categoryBlocks/index.js';

export function registerCrudRoutes(router, pool) {
  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const petId = req.query.pet_id || req.query.petId;
      let result;
      if (petId) {
        if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_VIEW))) {
          return res.status(403).json({ error: 'Forbidden' });
        }
        result = await pool.query(
          `SELECT he.*, p.name as pet_name, p.home_timezone AS pet_home_timezone FROM health_entries he
           JOIN pets p ON he.pet_id = p.id
           WHERE he.pet_id = $1 AND ${accessiblePetSql('p', '$2')}
           ORDER BY he.next_due_date ASC NULLS LAST, he.created_at DESC`,
          [petId, userId]
        );
      } else {
        result = await pool.query(
          `SELECT he.*, p.name as pet_name, p.home_timezone AS pet_home_timezone FROM health_entries he
           JOIN pets p ON he.pet_id = p.id
           WHERE ${accessiblePetSql('p', '$1')}
           ORDER BY he.next_due_date ASC NULLS LAST, he.created_at DESC`,
          [userId]
        );
      }
      res.json(await careItemsWire(pool, result.rows, req));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/export', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `SELECT he.*, p.name as pet_name FROM health_entries he
         JOIN pets p ON he.pet_id = p.id
         WHERE ${accessiblePetSql('p', '$1')}
         ORDER BY he.created_at DESC`,
        [userId]
      );
      let csv = 'id,pet_name,name,type,dosage,frequency,start_date,next_due_date,completed_on,recurrence_anchor,notes\n';
      for (const row of result.rows) {
        csv += [
          row.id, row.pet_name, row.name, row.type, row.dosage,
          row.frequency,
          dateToIsoDate(row.start_date),
          dateToIsoDate(row.next_due_date),
          dateToIsoDate(row.completed_on),
          row.recurrence_anchor, row.notes,
        ].map(csvCell).join(',') + '\n';
      }
      res.setHeader('Content-Type', 'text/csv');
      res.send(csv);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `SELECT he.*, p.name as pet_name FROM health_entries he
         JOIN pets p ON he.pet_id = p.id
         WHERE he.id = $1 AND ${accessiblePetSql('p', '$2')}`,
        [req.params.id, userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Entry not found' });
      res.json(await careItemWire(pool, result.rows[0], req));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const data = req.body;
      const id = data.id || uuidv4();
      const petId = data.pet_id || data.petId;
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_EDIT))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const startDate = normalizeCalendarDateInput(data.start_date || data.startDate);
      const nextDueDate = normalizeCalendarDateInput(data.next_due_date || data.nextDueDate);
      const completedOn = normalizeCalendarDateInput(data.completed_on || data.completedOn);
      const repeatEndDate = normalizeCalendarDateInput(data.repeat_end_date || data.repeatEndDate);
      const healthIssueId = data.health_issue_id || data.healthIssueId || null;
      try {
        assertAtLeastOneDate(nextDueDate, completedOn);
      } catch (e) {
        return res.status(400).json({ error: e.message });
      }
      const typeRejection = rejectClientTypeField(data);
      if (!typeRejection.ok) {
        return res.status(400).json({ error: typeRejection.error });
      }
      const scheduleTimes = parseScheduleTimesInput(data);
      const frequency = data.frequency || 'once';
      const isRecurring = frequency && frequency !== 'once';
      const careFamilyValidation = validateCareFamilyForWrite(
        data.care_family || data.careFamily,
        { requiredOnCreate: true },
      );
      if (!careFamilyValidation.ok) {
        return res.status(400).json({ error: careFamilyValidation.error });
      }
      const careSourceValidation = validateCareSourceForWrite(
        data.care_source || data.careSource,
      );
      if (!careSourceValidation.ok) {
        return res.status(400).json({ error: careSourceValidation.error });
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
        return res.status(400).json({ error: classification.error });
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
        return res.status(400).json({ error: e.message });
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
        return res.status(400).json({ error: scheduleShape.error, code: scheduleShape.code });
      }
      const providerResolved = await resolveEntryProviderForWrite(pool, userId, petId, data);
      if (providerResolved.error) {
        return res.status(400).json({
          error: providerResolved.error,
          ...(providerResolved.code ? { code: providerResolved.code } : {}),
        });
      }
      const { providerContactId, providerTypedName } = providerResolved;
      const { careBlocks, dosage: resolvedDosage } = resolveCareBlocksForWrite({
        data,
        careFamily,
      });
      const lateChoice = parseLateCompletionChoice(data);
      if (lateChoice.error) return res.status(400).json({ error: lateChoice.error });
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
        petId: petId,
        actorUserId: userId,
        eventType: 'health_log',
        metadata: { action: 'create', entry_type: derivedType },
      });
      res.status(201).json(await careItemWire(pool, entry, req, {
        openRows: out.openOccurrences,
        asOf: out.asOf,
      }));
    } catch (err) {
      if (sendCareCommandError(res, err)) return;
      res.status(500).json({ error: publicError(err, 'Error creating entry', `Error creating entry: ${err.message}`) });
    }
  });

  router.put('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageHealthEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const data = req.body;
      const startDate = normalizeCalendarDateInput(data.start_date || data.startDate);
      const nextDueDate = normalizeCalendarDateInput(data.next_due_date || data.nextDueDate);
      const completedOn = normalizeCalendarDateInput(data.completed_on || data.completedOn);
      const repeatEndDate = normalizeCalendarDateInput(data.repeat_end_date || data.repeatEndDate);
      const healthIssueId = data.health_issue_id || data.healthIssueId || null;
      try {
        assertAtLeastOneDate(nextDueDate, completedOn);
      } catch (e) {
        return res.status(400).json({ error: e.message });
      }
      const typeRejection = rejectClientTypeField(data);
      if (!typeRejection.ok) {
        return res.status(400).json({ error: typeRejection.error });
      }
      const lateChoice = parseLateCompletionChoice(data);
      if (lateChoice.error) return res.status(400).json({ error: lateChoice.error });
      const existingResult = await pool.query(
        'SELECT * FROM health_entries WHERE id = $1',
        [req.params.id],
      );
      if (existingResult.rows.length === 0) {
        return res.status(404).json({ error: 'Entry not found' });
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
        return res.status(400).json({ error: careFamilyValidation.error });
      }
      const careSourceValidation = validateCareSourceForWrite(
        data.care_source || data.careSource,
      );
      if (!careSourceValidation.ok) {
        return res.status(400).json({ error: careSourceValidation.error });
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
        return res.status(400).json({ error: classification.error });
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
        return res.status(400).json({ error: e.message });
      }
      const providerResolved = await resolveEntryProviderForWrite(
        pool,
        userId,
        existing.pet_id,
        data,
        existing,
      );
      if (providerResolved.error) {
        return res.status(400).json({
          error: providerResolved.error,
          ...(providerResolved.code ? { code: providerResolved.code } : {}),
        });
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
        return res.status(400).json({ error: scheduleShape.error, code: scheduleShape.code });
      }
      const existingStart = dateToIsoDate(existing.start_date);
      if (startDate && existingStart && startDate !== existingStart) {
        const closed = await pool.query(
          `SELECT 1 FROM health_occurrences
           WHERE health_entry_id = $1 AND status IN ('completed', 'skipped') LIMIT 1`,
          [req.params.id],
        );
        if (closed.rows.length > 0) {
          return res.status(400).json({
            error: 'The start date cannot change once care has been recorded',
            code: 'start_date_locked',
          });
        }
      }
      const status = carePlanning === 'unplanned'
        ? 'completed'
        : (existing.status || 'active');
      const out = await runCareCommand(pool, { entryId: req.params.id, userId, req }, async (ctx) => {
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
            req.params.id,
          ]
        );
        const edited = await applyLateCompletionChoice(ctx.db, updated.rows[0], lateChoice);
        return reconcileScheduleEdit({ ...ctx, entry: edited }, {
          before: ctx.entry,
          requestedNextDate: nextDueDate,
        });
      });
      if (!out) return res.status(404).json({ error: 'Entry not found' });
      const entry = out.entry;
      entry.pet_name = null;
      recordPetActivityForPet(pool, {
        petId: entry.pet_id,
        actorUserId: userId,
        eventType: 'health_log',
        metadata: { action: 'update', entry_type: derivedType },
      });
      res.json(await careItemWire(pool, entry, req, { openRows: out.openOccurrences, asOf: out.asOf }));
    } catch (err) {
      if (sendCareCommandError(res, err)) return;
      res.status(500).json({ error: publicError(err, 'Error updating entry', `Error updating entry: ${err.message}`) });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageHealthEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      await pool.query('DELETE FROM health_entries WHERE id = $1', [req.params.id]);
      res.json({ deleted: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
