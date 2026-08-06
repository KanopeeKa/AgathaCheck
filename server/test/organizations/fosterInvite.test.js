import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { buildMockPool } from './helpers.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const actorId = 'test-user-id';
const token = jwt.sign({ id: actorId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';

describe('POST /:orgId/foster-invite', () => {
  it('returns email channel for unknown email', async () => {
    const app = createApp(buildMockPool());
    const res = await request(app)
      .post(`/api/organizations/${orgId}/foster-invite`)
      .set('Authorization', `Bearer ${token}`)
      .send({ email: 'newfoster@example.com' });
    expect([201, 409]).toContain(res.statusCode);
    if (res.statusCode === 201) {
      expect(res.body.channel).toBe('email');
      expect(res.body.approval_state).toBe('under_review');
    }
  });

  it('returns 400 without email or user_ids', async () => {
    const app = createApp(buildMockPool());
    const res = await request(app)
      .post(`/api/organizations/${orgId}/foster-invite`)
      .set('Authorization', `Bearer ${token}`)
      .send({});
    expect(res.statusCode).toBe(400);
  });
});
