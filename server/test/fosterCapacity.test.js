import {
  availableCapacity,
  buildCapacityReadModel,
  declaredCapacityForSpecies,
  effectiveCompetencies,
  fosterHasCapacityForSpecies,
  parseSpeciesCapacities,
} from '../lib/fosterCapacity.js';

describe('fosterCapacity', () => {
  it('parses species capacities from JSON array', () => {
    expect(parseSpeciesCapacities([{ species: 'cat', declared: 2 }])).toEqual([
      { species: 'cat', declared: 2 },
    ]);
  });

  it('computes available capacity from declared minus session usage', () => {
    expect(availableCapacity(3, 1, 1)).toBe(1);
    expect(availableCapacity(1, 2, 0)).toBe(0);
  });

  it('prefers confirmed competencies over self-declared', () => {
    expect(effectiveCompetencies({
      self_declared_competencies: ['elderly'],
      confirmed_competencies: ['light_medical'],
    })).toEqual(['light_medical']);
  });

  it('builds capacity read model per species', () => {
    const model = buildCapacityReadModel({
      speciesCapacities: [{ species: 'dog', declared: 2 }],
      usageBySpecies: { dog: { preparation: 1, active: 0 } },
      species: 'dog',
    });
    expect(model).toEqual([{
      species: 'dog',
      declared: 2,
      preparation_count: 1,
      active_count: 0,
      available: 1,
    }]);
  });

  it('allows fosters without declared capacity data for a species', () => {
    expect(fosterHasCapacityForSpecies({
      speciesCapacities: [],
      usageBySpecies: {},
      species: 'cat',
    })).toBe(true);
  });

  it('rejects fosters with explicitly zero declared capacity', () => {
    expect(fosterHasCapacityForSpecies({
      speciesCapacities: [{ species: 'cat', declared: 0 }],
      usageBySpecies: {},
      species: 'cat',
    })).toBe(false);
  });

  it('reads declared capacity for a species', () => {
    const capacities = parseSpeciesCapacities([{ species: 'cat', declared: 4 }]);
    expect(declaredCapacityForSpecies(capacities, 'cat')).toBe(4);
  });
});
