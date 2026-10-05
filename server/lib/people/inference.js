const ORG_KEYWORDS =
  /\b(clinic|clinique|clinics|vets|veterinary|hospital|kennel|kennels|boarding|pension|cabinet|salon|ltd|limited|llp)\b/i;

/**
 * Infer person vs organisation without asking the user (creation only).
 * @param {{ name?: string, roles?: string[] }} input
 * @returns {'person'|'organisation'}
 */
export function inferContactKind(input) {
  const roles = input.roles || [];
  if (roles.includes('boarding')) return 'organisation';
  if (roles.includes('sitter') || roles.includes('walker')) return 'person';

  const name = (input.name || '').trim();
  if (name && ORG_KEYWORDS.test(name)) return 'organisation';
  return 'person';
}

/**
 * Derive UI group from roles and kind (server-only).
 * @param {string[]} roles
 * @param {'person'|'organisation'} kind
 * @returns {'carer'|'professional'}
 */
export function contactGroup(roles, kind) {
  const roleList = Array.isArray(roles) ? roles : [];
  if (kind === 'organisation') return 'professional';
  const professionalRoles = new Set([
    'vet',
    'vet_nurse',
    'groomer',
    'trainer',
    'behaviourist',
    'boarding',
  ]);
  const carerRoles = new Set(['sitter', 'walker', 'emergency_contact']);
  if (roleList.some((r) => professionalRoles.has(r))) return 'professional';
  if (roleList.some((r) => carerRoles.has(r))) return 'carer';
  if (roleList.includes('other')) return 'carer';
  return 'carer';
}
