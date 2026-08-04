import { publicError } from '../../config/security.js';
import { computeDisplayLocality } from './shared.js';

const DEFAULT_PAGE_SIZE = 20;
const MAX_PAGE_SIZE = 50;

function parsePagination(query) {
  let page = parseInt(query.page, 10);
  let pageSize = parseInt(query.page_size, 10);
  if (!Number.isFinite(page) || page < 1) page = 1;
  if (!Number.isFinite(pageSize) || pageSize < 1) pageSize = DEFAULT_PAGE_SIZE;
  if (pageSize > MAX_PAGE_SIZE) pageSize = MAX_PAGE_SIZE;
  const offset = (page - 1) * pageSize;
  return { page, pageSize, offset };
}

export function discoverRowToMap(row) {
  return {
    id: row.id,
    name: row.name,
    type: row.type || 'professional',
    logo_url: row.logo_url || '',
    photo_url: row.photo_url || '',
    display_locality: computeDisplayLocality(row),
    town: row.town || '',
    administrative_area: row.administrative_area || '',
    description: row.description || '',
  };
}

function parseSearchQuery(query) {
  const raw = typeof query.q === 'string' ? query.q.trim() : '';
  return raw;
}

function buildDiscoverWhereClause(searchQuery) {
  if (!searchQuery) {
    return {
      whereSql: 'WHERE is_discoverable = true',
      params: [],
    };
  }
  return {
    whereSql: 'WHERE is_discoverable = true AND name ILIKE $1',
    params: [`%${searchQuery}%`],
  };
}

export function registerDiscoverRoutes(router, pool) {
  router.get('/discover', async (req, res) => {
    const { page, pageSize, offset } = parsePagination(req.query);
    const searchQuery = parseSearchQuery(req.query);
    const { whereSql, params: whereParams } = buildDiscoverWhereClause(searchQuery);
    const limitOffsetParams = [pageSize, offset];
    const itemsParams = [...whereParams, ...limitOffsetParams];
    const limitOffsetStart = whereParams.length + 1;
    try {
      const [itemsResult, countResult] = await Promise.all([
        pool.query(
          `SELECT id, name, type, logo_url, photo_url, town, administrative_area,
                  description, public_profile_metadata
           FROM organizations
           ${whereSql}
           ORDER BY name ASC
           LIMIT $${limitOffsetStart} OFFSET $${limitOffsetStart + 1}`,
          itemsParams,
        ),
        pool.query(
          `SELECT COUNT(*)::int AS total_count
           FROM organizations
           ${whereSql}`,
          whereParams,
        ),
      ]);
      res.json({
        items: itemsResult.rows.map(discoverRowToMap),
        page,
        page_size: pageSize,
        total_count: countResult.rows[0]?.total_count ?? 0,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
