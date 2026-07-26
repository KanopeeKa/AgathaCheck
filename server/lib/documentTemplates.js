import { v4 as uuidv4 } from 'uuid';

export const TEMPLATE_TYPE_SESSION_CHECKLIST = 'session_checklist';
export const TEMPLATE_TYPE_ADOPTION_MILESTONE = 'adoption_milestone';

export const DEFAULT_SESSION_CHECKLIST_KEYS = [
  'foster_contract_prepared',
  'foster_contract_signed',
  'information_document_delivered',
  'veterinary_certificate_tracked',
  'register_entry_created',
];

export const DEFAULT_ADOPTION_MILESTONE_KEYS = [
  'commitment_certificate_signed',
  'adoption_contract_prepared',
  'transfer_date_set',
];

export function templateToMap(row) {
  return {
    id: row.id,
    organization_id: row.organization_id,
    template_key: row.template_key,
    template_type: row.template_type,
    label: row.label || row.template_key,
    description: row.description || '',
    sort_order: parseInt(row.sort_order, 10) || 0,
    is_required: row.is_required === true,
    is_public: row.is_public === true,
    created_at: row.created_at || null,
    updated_at: row.updated_at || null,
  };
}

export function publicTemplateToMap(row) {
  const mapped = templateToMap(row);
  return {
    id: mapped.id,
    template_key: mapped.template_key,
    template_type: mapped.template_type,
    label: mapped.label,
    description: mapped.description,
    sort_order: mapped.sort_order,
  };
}

export async function listPublicTemplatesForOrg(pool, orgId) {
  const result = await pool.query(
    `SELECT *
     FROM document_templates
     WHERE organization_id = $1
       AND is_public = true
     ORDER BY template_type, sort_order, label`,
    [orgId],
  );
  return result.rows.map(publicTemplateToMap);
}

export function groupPublicTemplatesByType(templates) {
  const grouped = {};
  for (const template of templates) {
    const type = template.template_type || 'other';
    if (!grouped[type]) grouped[type] = [];
    grouped[type].push(template);
  }
  return grouped;
}

export function buildPublicTemplateDownload(template) {
  const lines = [
    `# ${template.label}`,
    '',
    template.description ? template.description : '_No description provided._',
  ];
  return lines.join('\n');
}

export function parseChecklistItems(raw) {
  if (!raw || typeof raw !== 'object') return {};
  return raw;
}

export function renderChecklistFromTemplates(templates, storedItems = {}) {
  const items = parseChecklistItems(storedItems);
  return templates.map((template) => ({
    key: template.template_key,
    label: template.label || template.template_key,
    description: template.description || '',
    is_required: template.is_required === true,
    completed: items[template.template_key] === true,
    completed_at: items[`${template.template_key}_at`] || null,
  }));
}

export async function listTemplatesForOrg(pool, orgId, templateType) {
  const result = await pool.query(
    `SELECT *
     FROM document_templates
     WHERE organization_id = $1
       AND template_type = $2
     ORDER BY sort_order, label`,
    [orgId, templateType],
  );
  return result.rows.map(templateToMap);
}

export async function ensureDefaultTemplates(pool, orgId) {
  const defaults = [
    ...DEFAULT_SESSION_CHECKLIST_KEYS.map((key, index) => ({
      template_key: key,
      template_type: TEMPLATE_TYPE_SESSION_CHECKLIST,
      label: key.replace(/_/g, ' '),
      sort_order: index,
      is_required: ['foster_contract_signed', 'information_document_delivered'].includes(key),
    })),
    ...DEFAULT_ADOPTION_MILESTONE_KEYS.map((key, index) => ({
      template_key: key,
      template_type: TEMPLATE_TYPE_ADOPTION_MILESTONE,
      label: key.replace(/_/g, ' '),
      sort_order: index,
      is_required: key === 'adoption_contract_prepared',
    })),
  ];

  for (const item of defaults) {
    await pool.query(
      `INSERT INTO document_templates (
         id, organization_id, template_key, template_type, label, sort_order, is_required
       ) VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (organization_id, template_key) DO NOTHING`,
      [
        uuidv4(),
        orgId,
        item.template_key,
        item.template_type,
        item.label,
        item.sort_order,
        item.is_required,
      ],
    );
  }
}

function storageFromRenderedItems(items) {
  const next = {};
  for (const item of items) {
    next[item.key] = item.completed === true;
    if (item.completed_at) {
      next[`${item.key}_at`] = item.completed_at;
    }
  }
  return next;
}

function applyTemplateCompletion(templates, storedItems, itemKey, completed) {
  const rendered = renderChecklistFromTemplates(templates, storedItems);
  let found = false;
  const updated = rendered.map((item) => {
    if (item.key !== itemKey) return item;
    found = true;
    return {
      ...item,
      completed: completed === true,
      completed_at: completed === true ? new Date().toISOString() : null,
    };
  });
  if (!found) return null;
  return storageFromRenderedItems(updated);
}

export async function updateSessionChecklistItem(pool, {
  placementId,
  orgId,
  itemKey,
  completed,
}) {
  await ensureDefaultTemplates(pool, orgId);
  const templates = await listTemplatesForOrg(
    pool,
    orgId,
    TEMPLATE_TYPE_SESSION_CHECKLIST,
  );

  const placementResult = await pool.query(
    `SELECT id, session_checklist_items
     FROM foster_placements
     WHERE id = $1 AND organization_id = $2`,
    [placementId, orgId],
  );
  if (placementResult.rows.length === 0) {
    return { error: 'Placement not found', status: 404 };
  }

  const current = parseChecklistItems(placementResult.rows[0].session_checklist_items);
  const updated = applyTemplateCompletion(templates, current, itemKey, completed);
  if (!updated) {
    return { error: 'Unknown checklist item', status: 400 };
  }

  const result = await pool.query(
    `UPDATE foster_placements
     SET session_checklist_items = $1::jsonb,
         updated_at = NOW()
     WHERE id = $2
     RETURNING session_checklist_items`,
    [JSON.stringify(updated), placementId],
  );

  return { items: parseChecklistItems(result.rows[0].session_checklist_items), status: 200 };
}

export async function updateJourneyMilestoneItem(pool, {
  journeyId,
  orgId,
  itemKey,
  completed,
}) {
  await ensureDefaultTemplates(pool, orgId);
  const templates = await listTemplatesForOrg(
    pool,
    orgId,
    TEMPLATE_TYPE_ADOPTION_MILESTONE,
  );

  const journeyResult = await pool.query(
    `SELECT id, milestone_items
     FROM adoption_journeys
     WHERE id = $1 AND organization_id = $2`,
    [journeyId, orgId],
  );
  if (journeyResult.rows.length === 0) {
    return { error: 'Adoption journey not found', status: 404 };
  }

  const current = parseChecklistItems(journeyResult.rows[0].milestone_items);
  const updated = applyTemplateCompletion(templates, current, itemKey, completed);
  if (!updated) {
    return { error: 'Unknown checklist item', status: 400 };
  }

  const result = await pool.query(
    `UPDATE adoption_journeys
     SET milestone_items = $1::jsonb,
         updated_at = NOW()
     WHERE id = $2
     RETURNING milestone_items`,
    [JSON.stringify(updated), journeyId],
  );

  return { items: parseChecklistItems(result.rows[0].milestone_items), status: 200 };
}

export function buildRegisterExport({
  orgName,
  sessionTemplates,
  sessionItems,
  milestoneTemplates,
  milestoneItems,
  petName,
  fosterName,
}) {
  const lines = [
    `# Foster register export — ${orgName}`,
    '',
    `Pet: ${petName}`,
    `Foster: ${fosterName}`,
    '',
    '## Session checklist',
    ...renderChecklistFromTemplates(sessionTemplates, sessionItems).map(
      (item) => `- [${item.completed ? 'x' : ' '}] ${item.label}`,
    ),
    '',
    '## Adoption milestones',
    ...renderChecklistFromTemplates(milestoneTemplates, milestoneItems).map(
      (item) => `- [${item.completed ? 'x' : ' '}] ${item.label}`,
    ),
  ];
  return lines.join('\n');
}
