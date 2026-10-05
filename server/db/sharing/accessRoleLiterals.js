/**
 * Pet access role strings for SQL in db query modules.
 * Keep aligned with server/lib/petAccess.js role exports.
 */
export const CARER_ROLE = 'carer';
export const CO_PARENT_ROLE = 'co_parent';
export const FOSTER_PET_ACCESS_ROLE = 'foster';
export const PET_ACCESS_ROLES = [CARER_ROLE, CO_PARENT_ROLE];

export const PET_ACCESS_ROLES_SQL = PET_ACCESS_ROLES.map((role) => `'${role}'`).join(', ');
