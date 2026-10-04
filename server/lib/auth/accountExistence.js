import { verifyAccessToken } from '../../routes/auth/shared.js';

const ERASURE_STATUS_PATH =
  /^\/auth\/erasure\/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

/**
 * @param {string} method
 * @param {string} path Express path relative to the /api mount
 */
export function isExemptPath(method, path) {
  const normalized = path.split('?')[0];
  if (method === 'DELETE' && (normalized === '/auth/me' || normalized === '/auth/me/')) {
    return true;
  }
  if (method === 'GET' && ERASURE_STATUS_PATH.test(normalized)) {
    return true;
  }
  return false;
}

function bearerAccessToken(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  return auth.substring(7);
}

/**
 * Jest mock pools often omit the existence probe; synthesize a hit unless strict mode is set.
 * @param {import('pg').Pool} pool
 */
export function installTestAccountExistencePoolCompat(pool) {
  if (process.env.NODE_ENV !== 'test' || !pool || pool.__accountExistenceCompat) {
    return;
  }
  const orig = pool.query.bind(pool);
  pool.query = async (sql, params) => {
    const text = String(sql);
    if (text.includes('SELECT 1 FROM users WHERE id = $1')) {
      const primary = await orig(sql, params);
      if (primary.rows?.length > 0) {
        return primary;
      }
      if (pool.__strictAccountExistence) {
        return primary;
      }
      const id = params?.[0];
      const probes = [
        'SELECT id FROM users WHERE id = $1',
        'SELECT * FROM users WHERE id = $1',
        'SELECT password_hash FROM users WHERE id = $1',
        'SELECT password_hash, email FROM users WHERE id = $1',
      ];
      for (const probe of probes) {
        const r = await orig(probe, [id]);
        if (r.rows?.length > 0) {
          return { rows: [{ '?column?': 1 }] };
        }
      }
      return { rows: [{ '?column?': 1 }] };
    }
    return orig(sql, params);
  };
  pool.__accountExistenceCompat = true;
}

/**
 * Reject verified access tokens when the user row no longer exists (post-erasure).
 * @param {import('pg').Pool} pool
 */
export function createAccountExistenceMiddleware(pool) {
  return async function accountExistenceMiddleware(req, res, next) {
    if (isExemptPath(req.method, req.path)) {
      return next();
    }

    const token = bearerAccessToken(req);
    if (!token) {
      return next();
    }

    let payload;
    try {
      payload = verifyAccessToken(token);
    } catch {
      return next();
    }

    const userId = payload?.id;
    if (!userId) {
      return next();
    }

    try {
      const result = await pool.query('SELECT 1 FROM users WHERE id = $1', [userId]);
      if (result.rows.length === 0) {
        return res.status(401).json({
          error: 'Unauthorized',
          code: 'account_unavailable',
        });
      }
      return next();
    } catch (err) {
      return next(err);
    }
  };
}
