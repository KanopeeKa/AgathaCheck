import { publicError } from '../../config/security.js';

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
    logo_url: row.logo_url || '',
    town: row.town || '',
    administrative_area: row.administrative_area || '',
    description: row.description || '',
  };
}

export function registerDiscoverRoutes(router, pool) {
  router.get('/discover', async (req, res) => {
    const { page, pageSize, offset } = parsePagination(req.query);
    try {
      const [itemsResult, countResult] = await Promise.all([
        pool.query(
          `SELECT id, name, logo_url, town, administrative_area, description
           FROM organizations
           WHERE is_discoverable = true
           ORDER BY name ASC
           LIMIT $1 OFFSET $2`,
          [pageSize, offset],
        ),
        pool.query(
          `SELECT COUNT(*)::int AS total_count
           FROM organizations
           WHERE is_discoverable = true`,
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
