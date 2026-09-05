import {
  normalizeGender,
  normalizeSpecies,
  sanitizePhotoPathForWrite,
} from '../../lib/petProfileNormalize.js';

describe('petProfileNormalize', () => {
  describe('normalizeSpecies', () => {
    it('maps lowercase aliases to canonical title case', () => {
      expect(normalizeSpecies('dog')).toBe('Dog');
      expect(normalizeSpecies('cat')).toBe('Cat');
      expect(normalizeSpecies('bird')).toBe('Bird');
    });

    it('preserves canonical values', () => {
      expect(normalizeSpecies('Dog')).toBe('Dog');
      expect(normalizeSpecies('Horse / Poney')).toBe('Horse / Poney');
    });

    it('returns empty string for nullish input', () => {
      expect(normalizeSpecies(null)).toBe('');
      expect(normalizeSpecies('')).toBe('');
    });
  });

  describe('normalizeGender', () => {
    it('maps lowercase aliases to canonical title case', () => {
      expect(normalizeGender('male')).toBe('Male');
      expect(normalizeGender('female')).toBe('Female');
      expect(normalizeGender('m')).toBe('Male');
      expect(normalizeGender('f')).toBe('Female');
    });

    it('returns null for empty input', () => {
      expect(normalizeGender(null)).toBeNull();
      expect(normalizeGender('')).toBeNull();
    });
  });

  describe('sanitizePhotoPathForWrite', () => {
    it('accepts server upload paths', () => {
      expect(sanitizePhotoPathForWrite('/uploads/pet_photos/abc.jpg')).toEqual({
        ok: true,
        value: '/uploads/pet_photos/abc.jpg',
      });
    });

    it('rejects inline base64 data URLs', () => {
      expect(sanitizePhotoPathForWrite('data:image/png;base64,abc')).toEqual({
        ok: false,
        error: 'Photo must be uploaded using the photo endpoint',
      });
    });

    it('rejects non-upload paths', () => {
      expect(sanitizePhotoPathForWrite('https://example.com/photo.jpg')).toEqual({
        ok: false,
        error: 'Invalid photo path',
      });
    });

    it('allows null and empty to clear photo', () => {
      expect(sanitizePhotoPathForWrite(null)).toEqual({ ok: true, value: null });
      expect(sanitizePhotoPathForWrite('')).toEqual({ ok: true, value: null });
    });
  });
});
