import {
  defaultRetentionCategoryForParent,
  isValidRetentionCategory,
  FOSTER_RETENTION_CATEGORIES,
} from '../../lib/fosterCompliance.js';

describe('fosterCompliance', () => {
  describe('defaultRetentionCategoryForParent', () => {
    it('returns declined_archived for declined or archived approval', () => {
      expect(defaultRetentionCategoryForParent({
        approvalState: 'declined',
        creationSource: 'manual_shelter_entry',
        userId: null,
      })).toBe('declined_archived');
      expect(defaultRetentionCategoryForParent({
        approvalState: 'archived',
        creationSource: 'member',
        userId: 'user-1',
      })).toBe('declined_archived');
    });

    it('returns manual_contact for manual entry without user', () => {
      expect(defaultRetentionCategoryForParent({
        approvalState: 'under_review',
        creationSource: 'manual_shelter_entry',
        userId: null,
      })).toBe('manual_contact');
    });

    it('returns shelter_foster_relationship for approved linked fosters', () => {
      expect(defaultRetentionCategoryForParent({
        approvalState: 'approved',
        creationSource: 'member',
        userId: 'user-1',
      })).toBe('shelter_foster_relationship');
    });
  });

  describe('isValidRetentionCategory', () => {
    it('accepts G0-bounded categories only', () => {
      for (const category of FOSTER_RETENTION_CATEGORIES) {
        expect(isValidRetentionCategory(category)).toBe(true);
      }
      expect(isValidRetentionCategory('invalid')).toBe(false);
    });
  });
});
