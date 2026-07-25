import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { buildMockPool, makeOrgRow } from './helpers.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';
const memberId = 'member-user-id';
const inviteId = 'invite-1';


describe('Organizations API', () => {
  let app;

  beforeAll(() => {
    app = createApp(buildMockPool());
  });

  describe('Auth guard - 401 without token', () => {
      const endpoints = [
        ['GET', '/api/organizations'],
        ['POST', '/api/organizations'],
        ['GET', `/api/organizations/${orgId}`],
        ['PUT', `/api/organizations/${orgId}`],
        ['DELETE', `/api/organizations/${orgId}`],
        ['GET', '/api/organizations/invites/pending'],
        ['POST', `/api/organizations/invites/${inviteId}/accept`],
        ['POST', `/api/organizations/invites/${inviteId}/decline`],
        ['POST', '/api/organizations/join/abc123'],
        ['GET', `/api/organizations/${orgId}/members`],
        ['POST', `/api/organizations/${orgId}/invite`],
        ['DELETE', `/api/organizations/${orgId}/members/me`],
        ['GET', `/api/organizations/${orgId}/pets`],
        ['GET', `/api/organizations/${orgId}/archived`],
        // Previously unauthenticated admin routes — now require a token.
        ['POST', `/api/organizations/${orgId}/photo`],
        ['PUT', `/api/organizations/${orgId}/members/${memberId}/role`],
        ['DELETE', `/api/organizations/${orgId}/members/${memberId}`],
        ['POST', `/api/organizations/${orgId}/pets`],
        ['POST', `/api/organizations/${orgId}/pets/pet-1/transfer`],
        ['GET', `/api/organizations/${orgId}/pets/pet-1/foster-history`],
        ['GET', `/api/organizations/${orgId}/foster-parents`],
        ['GET', `/api/organizations/${orgId}/foster-parents/merge-suggestions`],
        ['GET', `/api/organizations/${orgId}/people`],
        ['GET', `/api/organizations/${orgId}/people/member/ou-1`],
        ['POST', `/api/organizations/${orgId}/foster-parents`],
        ['PUT', `/api/organizations/${orgId}/foster-parents/fp-1`],
        ['PATCH', `/api/organizations/${orgId}/foster-parents/fp-1/approval`],
        ['PATCH', `/api/organizations/${orgId}/foster-parents/fp-1/opt-out`],
        ['PATCH', `/api/organizations/${orgId}/foster-parents/fp-1/retention`],
        ['POST', `/api/organizations/${orgId}/foster-parents/fp-1/merge`],
        ['DELETE', `/api/organizations/${orgId}/foster-parents/fp-1`],
        ['GET', `/api/organizations/${orgId}/foster-requests`],
        ['POST', `/api/organizations/${orgId}/foster-requests`],
        ['GET', `/api/organizations/${orgId}/foster-requests/fr-1`],
        ['POST', `/api/organizations/${orgId}/foster-requests/fr-1/send`],
        ['POST', `/api/organizations/${orgId}/foster-requests/fr-1/responses`],
      ];
  
      endpoints.forEach(([method, url]) => {
        it(`${method} ${url} returns 401 without token`, async () => {
          const res = await request(app)[method.toLowerCase()](url).send({});
          expect(res.statusCode).toBe(401);
        });
      });
    });
});
