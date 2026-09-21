import careTaxonomy from '../../../shared/care_taxonomy.json';

type CareFamilyWire = keyof typeof careTaxonomy.families;

export function defaultCareFamilyForLegacyType(type: string): CareFamilyWire {
  const map = careTaxonomy.legacy_type_default_family as Record<string, CareFamilyWire>;
  return map[type] ?? 'other';
}

export function defaultCareFamilyWire(family: string): string {
  if (family in careTaxonomy.families) {
    return family;
  }
  return 'other';
}

export function deriveLegacyHealthEntryType(
  careFamily: string,
  careSetting: string,
): string {
  const definition = careTaxonomy.families[careFamily as CareFamilyWire];
  if (!definition) return 'other';
  const legacy = definition.derived_legacy_type[careSetting];
  return legacy ?? 'other';
}
