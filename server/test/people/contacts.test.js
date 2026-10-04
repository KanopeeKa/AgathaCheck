import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

function makeContactRow(overrides = {}) {
  return {
    id: 'contact-1',
    directory_id: 'dir-1',
    kind: 'person',
    name: 'Jamie Walker',
    phone: '555-0100',
    email: 'jamie@example.com',
    address: null,
    website: null,
    works_at_contact_id: null,
    linked_user_id: null,
    inactive_at: null,
    legacy_vet_id: null,
    roles: ['walker'],
    private_note: 'Great with nervous dogs',
    created_at: new Date('2025-01-01'),
    updated_at: new Date('2025-01-02'),
    ...overrides,
  };
}

describe('People contacts API', () => {
  let app;
  let lastQuery;
  const contacts = new Map();

  beforeAll(() => {
    contacts.set('contact-1', makeContactRow());

    const queryImpl = async (sql, params) => {
        lastQuery = { sql, params };

        if (sql.includes('SELECT id FROM people_directories WHERE owner_user_id')) {
          return { rows: [{ id: 'dir-1' }] };
        }
        if (sql.includes('INSERT INTO people_directories')) {
          return { rows: [{ id: 'dir-1' }] };
        }

        if (sql.includes('FROM people_contacts pc') && sql.includes('pd.owner_user_id = $2')
          && sql.includes('WHERE pc.id = $1')) {
          const id = params[0];
          const row = contacts.get(id);
          if (!row) return { rows: [] };
          return { rows: [row] };
        }

        if (sql.includes('FROM people_contacts pc') && sql.includes('pc.directory_id = $1')) {
          return { rows: [...contacts.values()] };
        }

        if (sql.includes('pc.directory_id = ANY')) {
          return { rows: [...contacts.values()] };
        }

        if (sql.includes('pet_contact_relationships pcr') && sql.includes('pcr.contact_id = ANY')) {
          return { rows: [] };
        }

        if (sql.includes('FROM people_contacts pc') && sql.includes('INNER JOIN people_directories pd')
          && sql.includes('WHERE pc.id = $1') && !sql.includes('pd.owner_user_id = $2')) {
          const id = params[0];
          const row = contacts.get(id);
          if (!row) return { rows: [] };
          return {
            rows: [{
              ...row,
              directory_household_id: null,
              owner_user_id: userId,
            }],
          };
        }

        if (sql.includes('FROM people_contacts pc') && sql.includes('pd.owner_user_id = $2')
          && sql.includes('WHERE pc.id = $1') && sql.includes('SELECT 1')) {
          return { rows: [{ '?column?': 1 }] };
        }

        if (sql.includes('health_occurrences')) {
          return { rows: [{ count: 0 }] };
        }

        if (sql.includes('planned_absence_pets pap')) {
          return { rows: [] };
        }

        if (sql.includes('health_entries he') && sql.includes('provider_contact_id')) {
          return { rows: [] };
        }

        if (sql.includes('INSERT INTO people_contacts')) {
          const id = params[0];
          const row = makeContactRow({
            id,
            directory_id: params[1],
            kind: params[2],
            name: params[3],
            phone: params[4],
            email: params[5],
            address: params[6],
            website: params[7],
            works_at_contact_id: params[8],
            roles: [],
            private_note: '',
          });
          contacts.set(id, row);
          return { rows: [row] };
        }

        if (sql.includes('INSERT INTO people_contact_roles')) {
          const contactId = params[0];
          const row = contacts.get(contactId);
          if (row) row.roles = [...(row.roles || []), params[1]];
          return { rows: [] };
        }

        if (sql.includes('INSERT INTO people_contact_private_notes')) {
          const contactId = params[0];
          const row = contacts.get(contactId);
          if (row) row.private_note = params[2];
          return { rows: [] };
        }

        if (sql.includes('UPDATE people_contacts SET')) {
          const contactId = params[10] ?? params[8];
          const row = contacts.get(contactId);
          if (!row) return { rows: [] };
          if (params[0] != null) row.kind = params[0];
          if (params[1] != null) row.name = params[1];
          if (params[7] !== undefined) {
            row.inactive_at = params[7];
          }
          contacts.set(contactId, row);
          return { rows: [row] };
        }

        if (sql.includes('DELETE FROM people_contact_roles')) {
          return { rows: [] };
        }

        if (sql.includes('DELETE FROM people_contacts WHERE id')) {
          contacts.delete(params[0]);
          return { rows: [] };
        }

        if (sql.includes('pet_contact_relationships')) {
          return { rows: [] };
        }

        return { rows: [] };
    };
    const clientQuery = async (sql, params) => {
      if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
        return { rows: [], command: sql };
      }
      return queryImpl(sql, params);
    };
    const mockPool = {
      query: clientQuery,
      connect: async () => ({
        query: clientQuery,
        release: () => {},
      }),
      end: async () => {},
    };
    app = createApp(mockPool);
  });

  it('GET /api/people/contacts returns 401 without token', async () => {
    const res = await request(app).get('/api/people/contacts');
    expect(res.statusCode).toBe(401);
  });

  it('GET /api/people/contacts lists contacts with private note', async () => {
    const res = await request(app)
      .get('/api/people/contacts')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body[0]).toMatchObject({
      id: 'contact-1',
      name: 'Jamie Walker',
      roles: ['walker'],
      private_note: 'Great with nervous dogs',
    });
  });

  it('POST /api/people/contacts creates a contact', async () => {
    const res = await request(app)
      .post('/api/people/contacts')
      .set('Authorization', `Bearer ${token}`)
      .send({ kind: 'person', name: 'New Sitter', roles: ['sitter'] });
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('name', 'New Sitter');
    expect(res.body.roles).toContain('sitter');
  });

  it('POST infers organisation kind from clinic name', async () => {
    const res = await request(app)
      .post('/api/people/contacts')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Greenhill Veterinary Clinic', roles: ['vet'] });
    expect(res.statusCode).toBe(201);
    expect(res.body.kind).toBe('organisation');
  });

  it('GET /api/people/contacts/:id returns one contact', async () => {
    const res = await request(app)
      .get('/api/people/contacts/contact-1')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.id).toBe('contact-1');
  });

  it('PATCH /api/people/contacts/:id updates contact', async () => {
    const res = await request(app)
      .patch('/api/people/contacts/contact-1')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Jamie W.' });
    expect(res.statusCode).toBe(200);
    expect(res.body.name).toBe('Jamie W.');
  });

  it('PATCH name without kind does not re-infer kind (B2)', async () => {
    contacts.set(
      'contact-org',
      makeContactRow({
        id: 'contact-org',
        kind: 'organisation',
        name: 'Greenhill Veterinary Clinic',
        roles: ['vet'],
        legacy_vet_id: 'vet-legacy-1',
      }),
    );
    const res = await request(app)
      .patch('/api/people/contacts/contact-org')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Greenhill Animal Hospital' });
    expect(res.statusCode).toBe(200);
    expect(res.body.kind).toBe('organisation');
    expect(res.body.name).toBe('Greenhill Animal Hospital');
  });

  it('PATCH linked contact name returns 409 linked_identity_read_only', async () => {
    contacts.set(
      'contact-linked',
      makeContactRow({
        id: 'contact-linked',
        linked_user_id: 'user-linked',
        name: 'Linked User',
        email: 'linked@example.com',
      }),
    );
    const res = await request(app)
      .patch('/api/people/contacts/contact-linked')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Changed' });
    expect(res.statusCode).toBe(409);
    expect(res.body.code).toBe('linked_identity_read_only');
  });

  it('PATCH validation errors include code', async () => {
    const res = await request(app)
      .patch('/api/people/contacts/contact-1')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: '' });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe('validation_failed');
  });

  it('DELETE /api/people/contacts/:id removes contact', async () => {
    contacts.set('contact-del', makeContactRow({ id: 'contact-del', legacy_vet_id: null }));
    const res = await request(app)
      .delete('/api/people/contacts/contact-del')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(lastQuery.sql).toContain('DELETE FROM people_contacts');
  });
});
