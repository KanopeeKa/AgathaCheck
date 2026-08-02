import { computeDisplayLocality } from '../../routes/organizations/shared.js';

describe('computeDisplayLocality', () => {
  it('prefers postcode from public_profile_metadata', () => {
    expect(
      computeDisplayLocality({
        town: 'Springfield',
        administrative_area: 'IL',
        public_profile_metadata: { postcode: '62701' },
      }),
    ).toBe('62701');
  });

  it('falls back to town when postcode is absent', () => {
    expect(
      computeDisplayLocality({
        town: 'Springfield',
        administrative_area: 'IL',
        public_profile_metadata: {},
      }),
    ).toBe('Springfield');
  });

  it('falls back to administrative_area when town is empty', () => {
    expect(
      computeDisplayLocality({
        town: '',
        administrative_area: 'IL',
        public_profile_metadata: {},
      }),
    ).toBe('IL');
  });

  it('returns empty string when no locality fields are set', () => {
    expect(
      computeDisplayLocality({
        town: '',
        administrative_area: '',
        public_profile_metadata: {},
      }),
    ).toBe('');
  });

  it('ignores blank postcode and uses town', () => {
    expect(
      computeDisplayLocality({
        town: 'Springfield',
        administrative_area: 'IL',
        public_profile_metadata: { postcode: '   ' },
      }),
    ).toBe('Springfield');
  });
});
