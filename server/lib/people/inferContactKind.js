const ORG_KEYWORDS =
  /\b(clinic|clinique|clinics|vets|veterinary|hospital|kennel|kennels|boarding|pension|cabinet|salon|ltd|limited|llp)\b/i;

/**
 * Infer person vs organisation without asking the user.
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
