import {
  buildCareFamilySuggestionDedupeKey,
  parseCareFamilySuggestionDedupeKey,
  SUGGESTION_TYPE_CARE_FAMILY,
} from '../routes/notifications/suggestionInbox.js';

describe('care-family suggestion dedupe keys', () => {
  it('maps care_family, suggestion_key, and pet id into a stable dedupe key', () => {
    const key = buildCareFamilySuggestionDedupeKey(
      'dental',
      'dental_review_rhythm',
      'pet-uuid-1',
    );
    expect(key).toBe('dental:dental_review_rhythm:pet-uuid-1');
  });

  it('parses dedupe keys produced for care recommendations', () => {
    const key = buildCareFamilySuggestionDedupeKey(
      'weight_monitoring',
      'weight_monitoring_rhythm',
      'abc-123',
    );
    expect(parseCareFamilySuggestionDedupeKey(key)).toEqual({
      careFamily: 'weight_monitoring',
      suggestionKey: 'weight_monitoring_rhythm',
      petId: 'abc-123',
    });
  });

  it('supports care_family values that contain colons', () => {
    const key = buildCareFamilySuggestionDedupeKey(
      'legacy:family',
      'some_key',
      'pet-9',
    );
    expect(parseCareFamilySuggestionDedupeKey(key)).toEqual({
      careFamily: 'legacy:family',
      suggestionKey: 'some_key',
      petId: 'pet-9',
    });
  });

  it('exports suggestionCareFamily wire type constant', () => {
    expect(SUGGESTION_TYPE_CARE_FAMILY).toBe('suggestionCareFamily');
  });
});
