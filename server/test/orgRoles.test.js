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

    it('passes through current roles', () => {
      expect(normaliseRole(ORG_ROLE_FOSTER)).toBe(ORG_ROLE_FOSTER);
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

    it('excludes foster', () => {
      expect(isOrgAdmin(ORG_ROLE_FOSTER)).toBe(false);
    });
  });

  describe('assignableRolesFor', () => {
    it('super_admin can assign all roles', () => {
      expect(assignableRolesFor(ORG_ROLE_SUPER_ADMIN)).toEqual(ASSIGNABLE_ROLES);
    });

    it('admin can assign associate and foster but not super_admin', () => {
      expect(assignableRolesFor(ORG_ROLE_ADMIN)).toEqual([
        ORG_ROLE_ADMIN,
        ORG_ROLE_FOSTER,
        ORG_ROLE_ASSOCIATE,
      ]);
      expect(canAssignRole(ORG_ROLE_ADMIN, ORG_ROLE_SUPER_ADMIN)).toBe(false);
      expect(canAssignRole(ORG_ROLE_ADMIN, ORG_ROLE_ASSOCIATE)).toBe(true);
    });

    it('foster cannot assign roles', () => {
      expect(assignableRolesFor(ORG_ROLE_FOSTER)).toEqual([]);
    });
  });

  describe('isFoster', () => {
    it('identifies foster role', () => {
      expect(isFoster(ORG_ROLE_FOSTER)).toBe(true);
      expect(isSuperAdmin(ORG_ROLE_FOSTER)).toBe(false);
    });
  });

  describe('isAssociate', () => {
    it('identifies associate role', () => {
      expect(isAssociate(ORG_ROLE_ASSOCIATE)).toBe(true);
      expect(isOrgAdmin(ORG_ROLE_ASSOCIATE)).toBe(false);
    });
  });

  describe('isFosterParentMember', () => {
    it('includes super_admin, admin, and foster', () => {
      expect(isFosterParentMember(ORG_ROLE_SUPER_ADMIN)).toBe(true);
      expect(isFosterParentMember(ORG_ROLE_ADMIN)).toBe(true);
      expect(isFosterParentMember(ORG_ROLE_FOSTER)).toBe(true);
    });

    it('excludes pending roles', () => {
      expect(isFosterParentMember('pending_foster')).toBe(false);
    });
  });
});
