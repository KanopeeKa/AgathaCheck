import jwt from 'jsonwebtoken';
import { handlePetAccessQuery } from '../helpers/petAccessMocks.js';

export const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
export const userId = 'test-user-id';
export const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });

export const PET_COLOR_PALETTE = [
  4286470082, 4287985101, 4284246976, 4286154443, 4283283116,
  4286695300, 4283417591, 4290406600, 4293943954, 4293227379,
  4294948685, 4288776319, 4287669422, 4284790262, 4289648001,
];

export const petId = '123e4567-e89b-12d3-a456-426614174000';
export const petId2 = '223e4567-e89b-12d3-a456-426614174001';

export function makePetRow(overrides = {}) {
  return {
    id: petId,
    user_id: userId,
    name: 'Fluffy',
    species: 'cat',
    breed: 'Persian',
    age: 3,
    date_of_birth: new Date('2021-01-15'),
    weight: 4.5,
    gender: 'female',
    bio: 'A lovely cat',
    insurance: 'PetPlan #123',
    neutered_date: new Date('2022-06-01'),
    neuter_dismissed: false,
    chip_id: 'CHIP-001',
    chip_dismissed: false,
    photo_path: '/uploads/fluffy.jpg',
    vet_id: 'vet-uuid-1',
    color_index: 0,
    passed_away: false,
    organization_id: 'org-uuid-1',
    created_at: new Date('2023-01-01'),
    updated_at: new Date('2023-06-01'),
    ...overrides,
  };
}

export function createMockPool(queryHandler) {
  return {
    query: queryHandler || (async (sql, params) => {
      const access = handlePetAccessQuery(sql, params, { userId, ownedPetIds: [petId, petId2] });
      if (access) return access;

      if (sql.includes('SELECT 1 FROM pets WHERE id = $1 AND user_id = $2')) {
        return { rows: [{ '?column?': 1 }] };
      }
      if (sql.includes('SELECT 1 FROM pet_access WHERE pet_id')) {
        return { rows: [] };
      }
      if (sql.includes('EXISTS') && sql.includes('AS is_foster') && sql.includes('WHERE p.id = $1')) {
        return { rows: [makePetRow()] };
      }
      if (sql.includes('false AS is_shared') || sql.includes('UNION ALL')) {
        return { rows: [makePetRow({ is_shared: false })] };
      }
      if (sql.includes('FROM pet_access pa') && sql.includes("role IN ('shared', 'guardian')")) {
        return { rows: [] };
      }
      if (sql.includes('DELETE FROM pet_access WHERE pet_id')) {
        return { rows: [{ id: 'pa-1' }] };
      }
      if (sql.includes('INSERT INTO notifications')) {
        return { rows: [] };
      }
      if (sql.includes('SELECT name FROM pets WHERE id = $1')) {
        return { rows: [{ name: 'Fluffy' }] };
      }
      if (sql.includes('SELECT organization_id, user_id FROM pets')) {
        return { rows: [{ organization_id: 'org-uuid-1', user_id: userId }] };
      }
      if (sql.includes('SELECT organization_id FROM pets')) {
        return { rows: [{ organization_id: 'org-uuid-1' }] };
      }
      if (sql.includes('SELECT organization_id, photo_path FROM pets')) {
        return { rows: [{ organization_id: 'org-uuid-1', photo_path: '/uploads/fluffy.jpg' }] };
      }
      if (sql.includes('SELECT 1 FROM organization_users')) {
        return { rows: [{ '?column?': 1 }] };
      }
      if (sql.includes('FROM family_events fe')) {
        return { rows: [] };
      }
      if (sql.includes('INSERT INTO family_events')) {
        return {
          rows: [{
            id: 'fe-1',
            pet_id: petId,
            organization_id: 'org-uuid-1',
            user_id: userId,
            from_date: '2023-01-01',
            to_date: null,
            notes: '',
            event_type: 'placement',
            assigned_to_user_id: null,
            created_by: userId,
          }],
        };
      }
      if (sql.includes('UPDATE family_events')) {
        return {
          rows: [{
            id: 'fe-1',
            pet_id: petId,
            organization_id: 'org-uuid-1',
            from_date: '2023-01-01',
            to_date: '2023-06-01',
            notes: '',
          }],
        };
      }
      if (sql.includes('DELETE FROM family_events')) {
        return { rows: [{ id: 'fe-1' }] };
      }
      if (sql.includes('INSERT INTO family_event_history')) {
        return { rows: [] };
      }
      if (sql.includes('SELECT * FROM family_events WHERE id')) {
        return {
          rows: [{
            id: 'fe-1',
            pet_id: petId,
            from_date: '2023-01-01',
            to_date: null,
            notes: '',
          }],
        };
      }
      if (sql.includes('SELECT first_name, last_name, email FROM users')) {
        return { rows: [{ first_name: 'Test', last_name: 'User', email: 'test@example.com' }] };
      }
      return { rows: [] };
    }),
    end: async () => {},
  };
}
