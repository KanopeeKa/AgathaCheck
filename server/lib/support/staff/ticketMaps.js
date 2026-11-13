function iso(value) {
  if (!value) return null;
  return value.toISOString?.() || String(value);
}

/**
 * @param {Record<string, unknown>} row
 */
export function mapStaffTicketSummary(row) {
  return {
    id: row.id,
    reference: row.reference,
    category: row.category,
    title: row.title,
    signed_in: Boolean(row.signed_in),
    reporter_email: row.reporter_email,
    created_at: iso(row.created_at),
    github_issue_number:
      row.github_issue_number != null ? Number(row.github_issue_number) : null,
    outbox_alerts: Array.isArray(row.outbox_alerts) ? row.outbox_alerts : [],
  };
}

/**
 * @param {Record<string, unknown>} row
 */
export function mapStaffTicketDetail(row) {
  return {
    id: row.id,
    reference: row.reference,
    user_id: row.user_id || null,
    reporter_email: row.reporter_email,
    reporter_email_normalised: row.reporter_email_normalised,
    signed_in: Boolean(row.signed_in),
    submit_ip: row.submit_ip || null,
    category: row.category,
    title: row.title,
    description: row.description,
    expected: row.expected || null,
    actual: row.actual || null,
    steps: row.steps || null,
    frequency: row.frequency || null,
    context: row.context ?? {},
    locale: row.locale,
    created_at: iso(row.created_at),
    github_issue_number:
      row.github_issue_number != null ? Number(row.github_issue_number) : null,
  };
}

/**
 * @param {Record<string, unknown>} row
 */
export function mapStaffAttachment(row) {
  return {
    id: row.id,
    mime: row.mime,
    bytes: Number(row.bytes),
    created_at: iso(row.created_at),
  };
}

/**
 * @param {Record<string, unknown>} row
 */
export function mapStaffOutboxRow(row) {
  return {
    id: row.id,
    kind: row.kind,
    status: row.status,
    attempts: Number(row.attempts),
    github_issue_number:
      row.github_issue_number != null ? Number(row.github_issue_number) : null,
    last_error: row.last_error || null,
    created_at: iso(row.created_at),
    updated_at: iso(row.updated_at),
  };
}
