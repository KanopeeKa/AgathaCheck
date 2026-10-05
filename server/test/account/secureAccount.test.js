import request from 'supertest';
import { createApp } from '../../bin/server.js';
import {
  buildMockPool,
  makeRefreshToken,
  makeToken,
  mockComparePassword,
  seedRefreshSession,
  userId,
} from '../auth/helpers.js';

describe('POST /api/auth/secure-account', () => {
  it('revokes other session families but keeps the current refresh session valid', async () => {
    const mockPool = buildMockPool();
    const refreshToken = makeRefreshToken();
    const session = seedRefreshSession(mockPool, refreshToken, { familyId: 'keep-family' });
    const otherToken = makeRefreshToken({ sid: 'other-session' });
    seedRefreshSession(mockPool, otherToken, { familyId: 'other-family' });

    const revokeCalls = [];
    const originalQuery = mockPool.query.bind(mockPool);
    mockPool.query = async (sql, params) => {
      if (sql.includes('family_id <> $2')) {
        revokeCalls.push(params);
      }
      return originalQuery(sql, params);
    };

    const app = createApp(mockPool, mockComparePassword);
    const res = await request(app)
      .post('/api/auth/secure-account')
      .set('Authorization', `Bearer ${makeToken()}`)
      .set('Cookie', `refresh_token=${refreshToken}`)
      .send({
        currentPassword: 'testpassword',
        newPassword: 'NewPassword456',
      });

    expect(res.statusCode).toBe(200);
    expect(revokeCalls.some((p) => p[1] === session.family_id)).toBe(true);

    const keepRow = mockPool._refreshSessions.get(session.id);
    expect(keepRow.revoked_at).toBeNull();

    const otherRow = [...mockPool._refreshSessions.values()].find(
      (r) => r.family_id === 'other-family',
    );
    expect(otherRow?.revoked_at).not.toBeNull();
  });
});
