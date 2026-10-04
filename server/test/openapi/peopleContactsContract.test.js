import request from 'supertest';
import jwt from 'jsonwebtoken';

import { createApp } from '../../bin/server.js';
import { assertMatchesSchema } from '../../lib/openapi/assertDto.js';
import {
  loadPetCareCriticalSpec,
  responseSchema,
} from '../../lib/openapi/petCareCriticalSpec.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'openapi-people-user';
const token = jwt.sign({ id: userId, email: 'openapi@example.com' }, JWT_SECRET, { expiresIn: '1h' });

const spec = loadPetCareCriticalSpec();

describe('People contacts OpenAPI contract', () => {
  it('PATCH 409 linked_identity_read_only matches PeopleApiError', async () => {
    const contacts = new Map([
      [
        'contact-linked',
        {
          id: 'contact-linked',
          directory_id: 'dir-1',
          kind: 'person',
          name: 'Linked',
          linked_user_id: 'u-2',
          email: 'a@b.com',
          roles: [],
          private_note: '',
          inactive_at: null,
        },
      ],
    ]);
    const queryImpl = async (sql, params) => {
      if (sql.includes('SELECT id FROM people_directories WHERE owner_user_id')) {
        return { rows: [{ id: 'dir-1' }] };
      }
      if (sql.includes('FROM people_contacts pc') && sql.includes('pd.owner_user_id = $2')) {
        const row = contacts.get(params[0]);
        return { rows: row ? [row] : [] };
      }
      if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
        return { rows: [], command: sql };
      }
      return { rows: [] };
    };
    const mockPool = {
      query: queryImpl,
      connect: async () => ({ query: queryImpl, release: () => {} }),
      end: async () => {},
    };
    const app = createApp(mockPool);
    const res = await request(app)
      .patch('/api/people/contacts/contact-linked')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Nope' });
    expect(res.statusCode).toBe(409);
    const schema = responseSchema(spec, '/people/contacts/{id}', 'patch', 409);
    assertMatchesSchema(spec, schema, res.body);
  });
});
