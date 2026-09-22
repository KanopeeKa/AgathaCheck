/**
 * Frozen domain mount gate — Shelter/Fostering APIs off unless explicitly enabled.
 * Default: false everywhere (local, UAT, production).
 */
export function frozenDomainsEnabled() {
  return process.env.ENABLE_FROZEN_DOMAINS === 'true';
}

/**
 * When Shelter/Fostering APIs are frozen, hide org-transfer and org-scoped family-event
 * mutations from active Pet Care mounts. Historical reads may remain available.
 */
export function rejectFrozenShelterApi(res) {
  if (frozenDomainsEnabled()) {
    return false;
  }
  res.status(404).json({ error: 'Not found' });
  return true;
}

/**
 * Reject organization linkage on Pet Care pet writes when frozen domains are off.
 */
export function rejectFrozenOrganizationIdOnPetWrite(req, res) {
  if (frozenDomainsEnabled()) {
    return false;
  }
  const body = req.body || {};
  const orgId = body.organization_id ?? body.organizationId;
  if (orgId != null && String(orgId).trim() !== '') {
    res.status(400).json({
      error: 'organization_id is not supported while frozen domains are disabled',
    });
    return true;
  }
  return false;
}
