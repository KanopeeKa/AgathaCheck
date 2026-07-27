/**
 * Builds a GDPR Art. 15/20 JSON export for a single user.
 * Used by GET /api/auth/me/export.
 */

export async function buildUserDataExport(pool, userId) {
  const [
    petsResult,
    vetsResult,
    healthEntriesResult,
    healthIssuesResult,
    healthHistoryResult,
    healthEventPhotosResult,
    healthIssueDocumentsResult,
    healthIssueEventsResult,
    weightEntriesResult,
    notificationsResult,
    notificationPrefsResult,
    orgMembershipsResult,
    organizationsResult,
    petAccessResult,
    shareLinksResult,
    sharedPetsResult,
    archivedPetsResult,
    familyEventsResult,
    fosterPlacementsResult,
    orgFosterParentLinksResult,
  ] = await Promise.all([
    pool.query('SELECT * FROM pets WHERE user_id = $1', [userId]),
    pool.query('SELECT * FROM vets WHERE user_id = $1', [userId]),
    pool.query('SELECT * FROM health_entries WHERE user_id = $1', [userId]),
    pool.query('SELECT * FROM health_issues WHERE user_id = $1', [userId]),
    pool.query(
      `SELECT hh.* FROM health_history hh
       INNER JOIN health_entries he ON he.id = hh.health_entry_id
       WHERE he.user_id = $1`,
      [userId],
    ),
    pool.query(
      `SELECT hep.* FROM health_event_photos hep
       INNER JOIN health_entries he ON he.id = hep.health_entry_id
       WHERE he.user_id = $1`,
      [userId],
    ),
    pool.query(
      `SELECT hid.* FROM health_issue_documents hid
       INNER JOIN health_issues hi ON hi.id = hid.health_issue_id
       WHERE hi.user_id = $1`,
      [userId],
    ),
    pool.query('SELECT * FROM health_issue_events WHERE user_id = $1', [userId]),
    pool.query('SELECT * FROM weight_entries WHERE user_id = $1', [userId]),
    pool.query(
      'SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC',
      [userId],
    ),
    pool.query('SELECT * FROM notification_preferences WHERE user_id = $1', [userId]),
    pool.query('SELECT * FROM organization_users WHERE user_id = $1', [userId]),
    pool.query(
      `SELECT o.* FROM organizations o
       INNER JOIN organization_users ou ON ou.organization_id = o.id
       WHERE ou.user_id = $1`,
      [userId],
    ),
    pool.query('SELECT * FROM pet_access WHERE user_id = $1', [userId]),
    pool.query('SELECT * FROM pet_share_links WHERE created_by = $1', [userId]),
    pool.query('SELECT * FROM shared_pets WHERE user_id = $1', [userId]),
    pool.query(
      `SELECT * FROM archived_pets
       WHERE user_id = $1 OR transferred_to_user_id = $1`,
      [userId],
    ),
    pool.query(
      `SELECT * FROM family_events
       WHERE user_id = $1 OR assigned_to_user_id = $1 OR created_by = $1`,
      [userId],
    ),
    pool.query(
      `SELECT * FROM foster_placements
       WHERE foster_user_id = $1 OR created_by = $1`,
      [userId],
    ),
    pool.query('SELECT * FROM org_foster_parents WHERE user_id = $1', [userId]),
  ]);

  return {
    pets: petsResult.rows,
    vets: vetsResult.rows,
    health_entries: healthEntriesResult.rows,
    health_issues: healthIssuesResult.rows,
    health_history: healthHistoryResult.rows,
    health_event_photos: healthEventPhotosResult.rows,
    health_issue_documents: healthIssueDocumentsResult.rows,
    health_issue_events: healthIssueEventsResult.rows,
    weight_entries: weightEntriesResult.rows,
    notifications: notificationsResult.rows,
    notification_preferences: notificationPrefsResult.rows,
    organization_memberships: orgMembershipsResult.rows,
    organizations: organizationsResult.rows,
    pet_access: petAccessResult.rows,
    pet_share_links: shareLinksResult.rows,
    shared_pets: sharedPetsResult.rows,
    archived_pets: archivedPetsResult.rows,
    family_events: familyEventsResult.rows,
    foster_placements: fosterPlacementsResult.rows,
    org_foster_parent_records: orgFosterParentLinksResult.rows,
  };
}

export function exportAuditMetadata(exportData) {
  return {
    pet_count: exportData.pets.length,
    vet_count: exportData.vets.length,
    health_entry_count: exportData.health_entries.length,
    health_issue_count: exportData.health_issues.length,
    weight_entry_count: exportData.weight_entries.length,
    notification_count: exportData.notifications.length,
    organization_count: exportData.organizations.length,
    pet_access_count: exportData.pet_access.length,
    share_link_count: exportData.pet_share_links.length,
  };
}
