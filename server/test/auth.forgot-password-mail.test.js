import request from 'supertest';

const userId = 'test-user-id-1';
const userEmail = 'testuser@example.com';

function restoreEnv(key, prev) {
  if (prev === undefined) {
    delete process.env[key];
  } else {
    process.env[key] = prev;
  }
}

function buildMockPool(overrides = {}) {
  const handlers = {
    selectUserByEmail: async () => ({ rows: [{ id: userId, locale: 'en' }] }),
    insertResetToken: async () => ({ rows: [] }),
    deleteResetToken: async () => ({ rows: [] }),
    fallback: async () => ({ rows: [] }),
    ...overrides,
  };

  return {
    query: async (sql, params) => {
      if (sql.includes('FROM users WHERE email') && sql.includes('SELECT id')) {
        return handlers.selectUserByEmail(sql, params);
      }
      if (sql.includes('INSERT INTO password_reset_tokens')) {
        return handlers.insertResetToken(sql, params);
      }
      if (sql.includes('DELETE FROM password_reset_tokens')) {
        return handlers.deleteResetToken(sql, params);
      }
      return handlers.fallback(sql, params);
    },
    end: async () => {},
  };
}

describe('forgot-password mail failures', () => {
  const savedEnv = {};

  beforeEach(() => {
    jest.resetModules();
    savedEnv.NODE_ENV = process.env.NODE_ENV;
    savedEnv.UAT_SMTP_HOST = process.env.UAT_SMTP_HOST;
    savedEnv.JWT_SECRET = process.env.JWT_SECRET;
    process.env.NODE_ENV = 'production';
    process.env.UAT_SMTP_HOST = 'smtp.example.com';
    process.env.JWT_SECRET = 'test-production-secret';
  });

  afterEach(() => {
    restoreEnv('NODE_ENV', savedEnv.NODE_ENV);
    restoreEnv('UAT_SMTP_HOST', savedEnv.UAT_SMTP_HOST);
    restoreEnv('JWT_SECRET', savedEnv.JWT_SECRET);
  });

  it('returns the same success response when email delivery fails', async () => {
    jest.unstable_mockModule('../services/mailService.js', () => ({
      sendPasswordResetEmail: jest.fn(async () => {
        throw new Error('SMTP down');
      }),
    }));

    const { createApp } = await import('../bin/server.js');
    const forgotApp = createApp(buildMockPool());

    const res = await request(forgotApp)
      .post('/api/auth/forgot-password')
      .send({ email: userEmail });

    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('message', 'If that email exists, a reset code has been sent.');
    expect(res.body).not.toHaveProperty('code');
  });

  it('still returns success when token rollback delete fails', async () => {
    jest.unstable_mockModule('../services/mailService.js', () => ({
      sendPasswordResetEmail: jest.fn(async () => {
        throw new Error('SMTP down');
      }),
    }));

    const { createApp } = await import('../bin/server.js');
    const forgotApp = createApp(buildMockPool({
      deleteResetToken: async () => {
        throw new Error('DB delete failed');
      },
    }));

    const res = await request(forgotApp)
      .post('/api/auth/forgot-password')
      .send({ email: userEmail });

    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('message', 'If that email exists, a reset code has been sent.');
  });
});
