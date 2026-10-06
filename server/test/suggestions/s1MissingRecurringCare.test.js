import { evaluateS1MissingRecurringCare } from '../../lib/suggestions/s1MissingRecurringCare.js';

describe('evaluateS1MissingRecurringCare', () => {
  const pet = {
    id: 'p1',
    name: 'Luna',
    species: 'cat',
    date_of_birth: '2024-01-01',
    passed_away: false,
  };

  it('returns a suggestion when parasite prevention rhythm is missing', () => {
    const result = evaluateS1MissingRecurringCare(
      pet,
      [],
      new Date('2026-06-01'),
    );
    expect(result).not.toBeNull();
    expect(result.wireType).toBe('suggestionMissingRecurringCare');
    expect(result.title).toContain('Luna');
  });

  it('returns null when recurring parasite prevention exists', () => {
    const result = evaluateS1MissingRecurringCare(
      pet,
      [{ care_family: 'parasite_prevention', frequency: 'monthly' }],
      new Date('2026-06-01'),
    );
    expect(result).toBeNull();
  });
});
