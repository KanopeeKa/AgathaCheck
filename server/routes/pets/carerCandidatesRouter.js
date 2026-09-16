import { publicError } from '../../config/security.js';
import { formatCarerCandidateDisplayName } from '../../lib/care/plannedAbsence.js';
import { PET_ACCESS_ROLES, userCanManageCare } from '../../lib/petAccess.js';
import { extractUserId } from './shared.js';

const PET_ACCESS_ROLES_SQL = PET_ACCESS_ROLES.map((role) => `'${role}'`).join(', ');

export function registerCarerCandidatesRoutes(router, pool) {
  router.get('/:id/carer-candidates', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id: petId } = req.params;
    try {
      if (!(await userCanManageCare(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const result = await pool.query(
        `SELECT u.id AS user_id, u.first_name, u.last_name, u.email
         FROM pet_access pa
         INNER JOIN users u ON u.id = pa.user_id
         WHERE pa.pet_id = $1
           AND pa.role IN (${PET_ACCESS_ROLES_SQL})
           AND COALESCE(pa.hidden, false) = false
         ORDER BY u.first_name, u.last_name, u.email`,
        [petId]
      );
      res.json(result.rows.map((row) => ({
        user_id: row.user_id,
        display_name: formatCarerCandidateDisplayName(row),
      })));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
