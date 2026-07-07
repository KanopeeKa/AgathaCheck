import jwt from 'jsonwebtoken';

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
  category: 'pet_guardian',
  bio: 'A test bio',
  photo_url: 'http://example.com/photo.png',
  locale: 'en',
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
};

export function makeToken(overrides = {}) {
  return jwt.sign(
    { id: userId, email: userEmail, ...overrides },
    JWT_SECRET,
    { expiresIn: '1h' },
  );
}

export function makeExpiredToken() {
  return jwt.sign({ id: userId, email: userEmail }, JWT_SECRET, { expiresIn: '-1s' });
}

export function makeRefreshToken(overrides = {}) {
  return jwt.sign(
    { id: userId, email: userEmail, ...overrides },
    JWT_SECRET,
    { expiresIn: '30d' },
  );
}

export function buildMockPool(overrides = {}) {
  const defaults = {
    insertUser: async (sql, params) => ({ rows: [{ id: userId }] }),
    selectUserByEmail: async (sql, params) => ({ rows: [userRow] }),
    selectUserById: async (sql, params) => ({ rows: [userRow] }),
    selectUserExists: async (sql, params) => ({ rows: [{ id: userId }] }),
    selectPasswordHash: async (sql, params) => ({ rows: [{ password_hash: userPasswordHash }] }),
    updateUser: async (sql, params) => ({ rows: [{ ...userRow, ...overrides.updatedFields }] }),
    deleteUser: async (sql, params) => ({ rows: [] }),
    selectPets: async (sql, params) => ({ rows: [{ id: 'pet-1', name: 'Buddy' }] }),
    selectVets: async (sql, params) => ({ rows: [{ id: 'vet-1', name: 'Dr. Smith' }] }),
    selectResetToken: async (sql, params) => ({ rows: [] }),
    insertResetToken: async (sql, params) => ({ rows: [] }),
    deleteResetToken: async (sql, params) => ({ rows: [] }),
    updateResetTokenUsed: async (sql, params) => ({ rows: [] }),
    updatePasswordHash: async (sql, params) => ({ rows: [] }),
    insertAuditEvent: async (sql, params) => ({ rows: [{ id: 'audit-event-1' }] }),
    fallback: async (sql, params) => ({ rows: [] }),
  };
  const handlers = { ...defaults, ...overrides };

  return {
    query: async (sql, params) => {
      if (sql.includes('INSERT INTO users')) return handlers.insertUser(sql, params);
      if (sql.includes('SELECT * FROM users WHERE email')) return handlers.selectUserByEmail(sql, params);
      if (sql.includes('SELECT id FROM users WHERE id')) return handlers.selectUserExists(sql, params);
      if (sql.includes('SELECT * FROM users WHERE id')) return handlers.selectUserById(sql, params);
      if (sql.includes('SELECT password_hash FROM users WHERE id')) return handlers.selectPasswordHash(sql, params);
      if (sql.includes('UPDATE users SET password_hash')) return handlers.updatePasswordHash(sql, params);
      if (sql.includes('UPDATE users SET') && !sql.includes('password_hash')) return handlers.updateUser(sql, params);
      if (sql.includes('DELETE FROM users')) return handlers.deleteUser(sql, params);
      if (sql.includes('SELECT * FROM pets')) return handlers.selectPets(sql, params);
      if (sql.includes('SELECT * FROM vets')) return handlers.selectVets(sql, params);
      if (sql.includes('FROM users WHERE email') && sql.includes('SELECT id')) return handlers.selectUserByEmail(sql, params);
      if (sql.includes('INSERT INTO password_reset_tokens')) return handlers.insertResetToken(sql, params);
      if (sql.includes('DELETE FROM password_reset_tokens')) return handlers.deleteResetToken(sql, params);
      if (sql.includes('SELECT prt.id')) return handlers.selectResetToken(sql, params);
      if (sql.includes('UPDATE password_reset_tokens')) return handlers.updateResetTokenUsed(sql, params);
      if (sql.includes('INSERT INTO audit_events')) return handlers.insertAuditEvent(sql, params);
      return handlers.fallback(sql, params);
    },
    end: async () => {},
  };
}

export function mockComparePassword(inputPassword, hash) {
  if (inputPassword === 'testpassword' && hash === userPasswordHash) return true;
  return false;
}
