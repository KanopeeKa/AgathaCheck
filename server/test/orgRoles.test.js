import {
  ASSIGNABLE_ROLES,
  ORG_ROLE_ADMIN,
  ORG_ROLE_ASSOCIATE,
  ORG_ROLE_FOSTER,
  ORG_ROLE_SUPER_ADMIN,
  assignableRolesFor,
  canAssignRole,
  isActiveMember,
  isAssociate,
  isFoster,
  isFosterParentMember,
  isOrgAdmin,
  isSuperAdmin,
  normaliseRole,
} from '../lib/orgRoles.js';

describe('orgRoles', () => {
  describe('normaliseRole', () => {
    it('maps legacy super_user to super_admin', () => {
      expect(normaliseRole('super_user')).toBe(ORG_ROLE_SUPER_ADMIN);
    });

    it('maps legacy member to super_admin', () => {
      expect(normaliseRole('member')).toBe(ORG_ROLE_SUPER_ADMIN);
    });

    it('maps legacy foster wire to associate', () => {
      expect(normaliseRole(ORG_ROLE_FOSTER)).toBe(ORG_ROLE_ASSOCIATE);
      expect(normaliseRole('pending_foster')).toBe('pending_associate');
    });

    it('passes through current roles', () => {
      expect(normaliseRole(ORG_ROLE_ASSOCIATE)).toBe(ORG_ROLE_ASSOCIATE);
    });
  });

  describe('isActiveMember', () => {
    it('rejects pending roles', () => {
      expect(isActiveMember('pending_admin')).toBe(false);
    });

    it('accepts admin', () => {
      expect(isActiveMember(ORG_ROLE_ADMIN)).toBe(true);
    });
  });

  describe('isOrgAdmin', () => {
    it('includes super_admin and admin', () => {
      expect(isOrgAdmin(ORG_ROLE_SUPER_ADMIN)).toBe(true);
      expect(isOrgAdmin(ORG_ROLE_ADMIN)).toBe(true);
    });

    it('excludes foster wire', () => {
      expect(isOrgAdmin(ORG_ROLE_FOSTER)).toBe(false);
    });
  });

  describe('assignableRolesFor', () => {
    it('super_admin can assign associate, admin, and super_admin', () => {
      expect(assignableRolesFor(ORG_ROLE_SUPER_ADMIN)).toEqual(ASSIGNABLE_ROLES);
      expect(ASSIGNABLE_ROLES).not.toContain(ORG_ROLE_FOSTER);
    });

    it('admin can assign associate and admin but not super_admin', () => {
      expect(assignableRolesFor(ORG_ROLE_ADMIN)).toEqual([
        ORG_ROLE_ADMIN,
        ORG_ROLE_ASSOCIATE,
      ]);
      expect(canAssignRole(ORG_ROLE_ADMIN, ORG_ROLE_SUPER_ADMIN)).toBe(false);
      expect(canAssignRole(ORG_ROLE_ADMIN, ORG_ROLE_ASSOCIATE)).toBe(true);
    });

    it('associate cannot assign roles', () => {
      expect(assignableRolesFor(ORG_ROLE_ASSOCIATE)).toEqual([]);
    });
  });

  describe('isFoster', () => {
    it('identifies legacy foster wire value', () => {
      expect(isFoster(ORG_ROLE_FOSTER)).toBe(true);
      expect(isSuperAdmin(ORG_ROLE_FOSTER)).toBe(false);
    });
  });

  describe('isAssociate', () => {
    it('identifies associate role including normalised foster', () => {
      expect(isAssociate(ORG_ROLE_ASSOCIATE)).toBe(true);
      expect(isAssociate(ORG_ROLE_FOSTER)).toBe(true);
      expect(isOrgAdmin(ORG_ROLE_ASSOCIATE)).toBe(false);
    });
  });

  describe('isFosterParentMember', () => {
    it('includes super_admin and admin only', () => {
      expect(isFosterParentMember(ORG_ROLE_SUPER_ADMIN)).toBe(true);
      expect(isFosterParentMember(ORG_ROLE_ADMIN)).toBe(true);
      expect(isFosterParentMember(ORG_ROLE_FOSTER)).toBe(false);
      expect(isFosterParentMember(ORG_ROLE_ASSOCIATE)).toBe(false);
    });

    it('excludes pending roles', () => {
      expect(isFosterParentMember('pending_foster')).toBe(false);
    });
  });
});
