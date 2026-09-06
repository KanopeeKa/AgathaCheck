import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';

import { hashRefreshToken } from '../../lib/refreshSessions.js';
import { TOKEN_TYPE_ACCESS, TOKEN_TYPE_REFRESH } from '../../routes/auth/shared.js';

export const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

export const userId = 'test-user-id-1';
export const userEmail = 'testuser@example.com';
export const userPasswordHash = '$2b$10$validhashfortestpassword';
export const userRow = {
  id: userId,
  email: userEmail,
  password_hash: userPasswordHash,
  first_name: 'Test',
  last_name: 'User',
  category: 'pet_carer',
  bio: 'A test bio',
  photo_url: 'http://example.com/photo.png',
  locale: 'en',
  pinned_organization_id: null,
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
};

export function makeToken(overrides = {}) {
  return jwt.sign(
    { id: userId, email: userEmail, typ: TOKEN_TYPE_ACCESS, ...overrides },
    JWT_SECRET,
    { expiresIn: '1h' },
  );
}

export function makeExpiredToken() {
  return jwt.sign(
    { id: userId, email: userEmail, typ: TOKEN_TYPE_ACCESS },
    JWT_SECRET,
    { expiresIn: '-1s' },
  );
}

export function makeRefreshToken(overrides = {}) {
  const sid = overrides.sid || uuidv4();
  const { sid: _ignored, ...rest } = overrides;
  return jwt.sign(
    { id: userId, email: userEmail, typ: TOKEN_TYPE_REFRESH, sid, ...rest },
    JWT_SECRET,
    { expiresIn: '30d' },
  );
}

export function seedRefreshSession(mockPool, refreshToken, options = {}) {
  const decoded = jwt.decode(refreshToken);
  const row = {
    id: decoded.sid,
    user_id: decoded.id,
    token_hash: hashRefreshToken(refreshToken),
    family_id: options.familyId || uuidv4(),
    rotated_from: options.rotatedFrom || null,
    revoked_at: options.revokedAt || null,
    expires_at: options.expiresAt || new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    created_at: new Date(),
  };
  mockPool._refreshSessions.set(row.id, row);
  if (!mockPool._refreshSessionsByHash.has(row.token_hash)) {
    mockPool._refreshSessionsByHash.set(row.token_hash, row);
  }
  return row;
}

export function buildMockPool(overrides = {}) {
  const defaults = {
    insertUser: async (sql, params) => ({ rows: [{ id: userId }] }),
    selectUserByEmail: async (sql, params) => ({ rows: [userRow] }),
    selectUserById: async (sql, params) => ({ rows: [userRow] }),
    selectUserExists: async (sql, params) => ({ rows: [{ id: userId }] }),
    selectPasswordHash: async (sql, params) => ({ rows: [{ password_hash: userPasswordHash }] }),
    updateUser: async (sql, params) => ({ rows: [{ ...userRow, ...overrides.updatedFields }] }),
    clearPinnedOrg: async (sql, params) => ({ rows: [] }),
    selectOrgMembership: async (sql, params) => ({ rows: [] }),
    deleteUser: async (sql, params) => ({ rows: [] }),
    selectPets: async (sql, params) => ({ rows: [{ id: 'pet-1', name: 'Buddy' }] }),
    selectVets: async (sql, params) => ({ rows: [{ id: 'vet-1', name: 'Dr. Smith' }] }),
    selectExportSection: async (sql, params) => ({ rows: [] }),
    selectResetToken: async (sql, params) => ({ rows: [] }),
    insertResetToken: async (sql, params) => ({ rows: [] }),
    deleteResetToken: async (sql, params) => ({ rows: [] }),
    updateResetTokenUsed: async (sql, params) => ({ rows: [] }),
    updatePasswordHash: async (sql, params) => ({ rows: [] }),
    insertAuditEvent: async (sql, params) => ({ rows: [{ id: 'audit-event-1' }] }),
    fallback: async (sql, params) => ({ rows: [] }),
  };
  const handlers = { ...defaults, ...overrides };
  const refreshSessions = new Map();
  const refreshSessionsByHash = new Map();

  const pool = {
    _refreshSessions: refreshSessions,
    _refreshSessionsByHash: refreshSessionsByHash,
    query: async (sql, params) => {
      if (sql.includes('INSERT INTO users')) return handlers.insertUser(sql, params);
      if (sql.includes('SELECT * FROM users WHERE email')) return handlers.selectUserByEmail(sql, params);
      if (sql.includes('SELECT id FROM users WHERE id')) return handlers.selectUserExists(sql, params);
      if (sql.includes('SELECT * FROM users WHERE id')) return handlers.selectUserById(sql, params);
      if (sql.includes('SELECT password_hash FROM users WHERE id')) return handlers.selectPasswordHash(sql, params);
      if (sql.includes('SELECT role FROM organization_users WHERE organization_id')) {
        return handlers.selectOrgMembership(sql, params);
      }
      if (sql.includes('UPDATE users SET pinned_organization_id = NULL')) return handlers.clearPinnedOrg(sql, params);
      if (sql.includes('UPDATE users SET password_hash')) return handlers.updatePasswordHash(sql, params);
      if (sql.includes('UPDATE users SET') && !sql.includes('password_hash')) return handlers.updateUser(sql, params);
      if (sql.includes('DELETE FROM users')) return handlers.deleteUser(sql, params);
      if (sql.includes('SELECT * FROM pets')) return handlers.selectPets(sql, params);
      if (sql.includes('SELECT * FROM vets')) return handlers.selectVets(sql, params);
      if (sql.includes('FROM health_entries') || sql.includes('FROM health_issues')
        || sql.includes('FROM health_history') || sql.includes('FROM health_event_photos')
        || sql.includes('FROM health_issue_documents') || sql.includes('FROM health_issue_events') || sql.includes('FROM weight_entries')
        || sql.includes('FROM notifications') || sql.includes('FROM notification_preferences')
        || sql.includes('FROM organization_users') || sql.includes('FROM organizations o')
        || sql.includes('FROM pet_access') || sql.includes('FROM pet_share_links')
        || sql.includes('FROM shared_pets') || sql.includes('FROM archived_pets')
        || sql.includes('FROM family_events') || sql.includes('FROM foster_placements')
        || sql.includes('FROM org_foster_parents')) {
        return handlers.selectExportSection(sql, params);
      }
      if (sql.includes('FROM users WHERE email') && sql.includes('SELECT id')) return handlers.selectUserByEmail(sql, params);
      if (sql.includes('INSERT INTO password_reset_tokens')) return handlers.insertResetToken(sql, params);
      if (sql.includes('DELETE FROM password_reset_tokens')) return handlers.deleteResetToken(sql, params);
      if (sql.includes('SELECT prt.id')) return handlers.selectResetToken(sql, params);
      if (sql.includes('UPDATE password_reset_tokens')) return handlers.updateResetTokenUsed(sql, params);
      if (sql.includes('INSERT INTO audit_events')) return handlers.insertAuditEvent(sql, params);
      if (sql.includes('INSERT INTO refresh_sessions')) {
        const [id, userIdParam, tokenHash, familyId, rotatedFrom, expiresAt] = params;
        const row = {
          id,
          user_id: userIdParam,
          token_hash: tokenHash,
          family_id: familyId,
          rotated_from: rotatedFrom,
          revoked_at: null,
          expires_at: expiresAt,
          created_at: new Date(),
        };
        refreshSessions.set(id, row);
        refreshSessionsByHash.set(tokenHash, row);
        return { rows: [row] };
      }
      if (sql.includes('FROM refresh_sessions') && sql.includes('WHERE id = $1')) {
        const row = refreshSessions.get(params[0]);
        return { rows: row ? [row] : [] };
      }
      if (sql.includes('UPDATE refresh_sessions') && sql.includes('WHERE user_id = $1')) {
        for (const row of refreshSessions.values()) {
          if (row.user_id === params[0] && !row.revoked_at) {
            row.revoked_at = new Date();
          }
        }
        return { rows: [] };
      }
      if (sql.includes('UPDATE refresh_sessions') && sql.includes('WHERE family_id = $1')) {
        for (const row of refreshSessions.values()) {
          if (row.family_id === params[0] && !row.revoked_at) {
            row.revoked_at = new Date();
          }
        }
        return { rows: [] };
      }
      if (sql.includes('UPDATE refresh_sessions') && sql.includes('WHERE id = $1')) {
        const row = refreshSessions.get(params[0]);
        if (row) row.revoked_at = new Date();
        return { rows: [] };
      }
      return handlers.fallback(sql, params);
    },
    end: async () => {},
  };

  return pool;
}

export function mockComparePassword(inputPassword, hash) {
  if (inputPassword === 'testpassword' && hash === userPasswordHash) return true;
  return false;
}
