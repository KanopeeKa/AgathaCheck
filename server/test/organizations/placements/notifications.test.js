import request from 'supertest';
import { createApp } from '../../../bin/server.js';
import {
  NOTIFICATION_TYPE_PENDING_ADOPTION_PLACEMENT_RECEIVED,
  NOTIFICATION_TYPE_PENDING_FOSTER_PLACEMENT_RECEIVED,
} from '../../../lib/notificationKind.js';
import {
  adminToken,
  buildFosterPlacementMockPool,
  fosterId,
  orgId,
  petId,
} from '../../helpers/fosterPlacementMockPool.js';

describe('Placement create notifications', () => {
  it('POST placements inserts pending foster notification for foster parent', async () => {
    const notifications = [];
    const pool = buildFosterPlacementMockPool();
    const originalQuery = pool.query.bind(pool);
    pool.query = async (sql, params) => {
      if (sql.includes('INSERT INTO notifications')) {
        notifications.push({
          userId: params[1],
          petId: params[2],
          petName: params[3],
          organizationId: params[5],
          title: params[6],
          message: params[7],
          type: params[8],
        });
      }
      return originalQuery(sql, params);
    };
    const app = createApp(pool);

    const res = await request(app)
      .post(`/api/organizations/${orgId}/pets/${petId}/placements`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ foster_user_id: fosterId, notes: 'Welcome foster' });

    expect(res.statusCode).toBe(201);
    expect(notifications).toHaveLength(1);
    expect(notifications[0]).toMatchObject({
      userId: fosterId,
      petId,
      petName: 'Buddy',
      organizationId: orgId,
      type: NOTIFICATION_TYPE_PENDING_FOSTER_PLACEMENT_RECEIVED,
    });
    expect(notifications[0].message).toContain('Buddy');
  });

  it('POST direct-adopt inserts pending adoption notification for foster parent', async () => {
    const notifications = [];
    const pool = buildFosterPlacementMockPool();
    const originalQuery = pool.query.bind(pool);
    pool.query = async (sql, params) => {
      if (sql.includes('INSERT INTO notifications')) {
        notifications.push({
          userId: params[1],
          petId: params[2],
          petName: params[3],
          organizationId: params[5],
          title: params[6],
          message: params[7],
          type: params[8],
        });
      }
      return originalQuery(sql, params);
    };
    const app = createApp(pool);

    const res = await request(app)
      .post(`/api/organizations/${orgId}/pets/${petId}/placements/direct-adopt`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        foster_user_id: fosterId,
        adoption_conditions: 'Must be neutered first',
      });

    expect(res.statusCode).toBe(201);
    expect(notifications).toHaveLength(1);
    expect(notifications[0]).toMatchObject({
      userId: fosterId,
      petId,
      petName: 'Buddy',
      organizationId: orgId,
      type: NOTIFICATION_TYPE_PENDING_ADOPTION_PLACEMENT_RECEIVED,
    });
    expect(notifications[0].message).toContain('Pre-adoption conditions apply');
  });
});
