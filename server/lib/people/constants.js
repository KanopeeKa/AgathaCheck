export const CONTACT_KINDS = ['person', 'organisation'];

/** Maps each role to roster section group (server-derived). */
export const ROLE_GROUP = {
  sitter: 'carer',
  walker: 'carer',
  emergency_contact: 'carer',
  vet: 'professional',
  vet_nurse: 'professional',
  groomer: 'professional',
  trainer: 'professional',
  behaviourist: 'professional',
  boarding: 'professional',
  other: 'carer',
};

export const CONTACT_ROLES = [
  'sitter',
  'walker',
  'vet',
  'vet_nurse',
  'groomer',
  'trainer',
  'behaviourist',
  'boarding',
  'emergency_contact',
  'other',
];

export const RELATIONSHIP_KINDS = [
  'primary_vet',
  'out_of_hours_vet',
  'emergency_contact',
  'care_provider',
  'other',
];

/** Slot kinds — at most one active row per pet (I4). */
export const SLOT_RELATIONSHIP_KINDS = ['primary_vet', 'out_of_hours_vet'];
