/** Species where vaccination history welfare applies (dog/cat guardianship norms). */
export const VACCINATION_WELFARE_SPECIES = new Set(['Dog', 'Cat']);

export function speciesSupportsVaccinationWelfare(species) {
  if (!species) return false;
  return VACCINATION_WELFARE_SPECIES.has(String(species));
}
