/** Species where neutering is not applicable (align with Flutter AppConstants). */
export const SPECIES_WITHOUT_NEUTERING = new Set([
  'Bird',
  'Fish',
  'Hamster',
  'Ferret',
  'Horse / Poney',
]);

export function speciesSupportsNeutering(species) {
  if (!species) return false;
  return !SPECIES_WITHOUT_NEUTERING.has(String(species));
}
