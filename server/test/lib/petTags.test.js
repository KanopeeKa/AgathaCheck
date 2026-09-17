import {
  normalizeTagName,
  TagValidationError,
} from '../../lib/petTags.js';

describe('petTags lib', () => {
  describe('normalizeTagName', () => {
    it('trims whitespace', () => {
      expect(normalizeTagName('  Weekend  ')).toBe('Weekend');
    });

    it('rejects empty names', () => {
      expect(() => normalizeTagName('   ')).toThrow(TagValidationError);
    });

    it('rejects names over 64 characters', () => {
      expect(() => normalizeTagName('a'.repeat(65))).toThrow(TagValidationError);
    });
  });
});
