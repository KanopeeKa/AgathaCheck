import path from 'path';
import multer from 'multer';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';

import { JWT_SECRET } from '../../config/jwtSecret.js';
import { hasPermissionForUser } from '../../lib/orgPermissions.js';
import {
  isActiveMember,
  isOrgAdmin,
  isSuperAdmin,
  normaliseRole,
} from '../../lib/orgRoles.js';

/** Keys allowed in public_profile_metadata on unauthenticated-safe endpoints. */
export const SAFE_PUBLIC_PROFILE_METADATA_KEYS = ['postcode'];
import { extensionForMime, normalizeMimeType, saveUploadedFile, validateOrgImageMime } from '../../lib/safeUpload.js';

const MAX_ORG_IMAGE_BYTES = 2 * 1024 * 1024;
const ORG_IMAGE_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.webp']);

const orgImageUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_ORG_IMAGE_BYTES },
  fileFilter: (_req, file, cb) => {
    try {
      const normalized = normalizeMimeType(file.mimetype);
      if (!normalized || normalized === 'application/octet-stream') {
        cb(null, true);
        return;
      }
      extensionForMime(normalized, ORG_IMAGE_EXTENSIONS);
      file.mimetype = normalized;
      cb(null, true);
    } catch {
      cb(new Error('Only JPG, PNG, and WebP images are allowed'));
    }
  },
});

export const ORG_COUNT_SELECT = `
  (SELECT COUNT(*) FROM organization_users
    WHERE organization_id = o.id AND role NOT LIKE 'pending_%') as member_count,
  (SELECT COUNT(*) FROM org_foster_parents
    WHERE organization_id = o.id) as external_count,
  (SELECT COUNT(*) FROM pets
    WHERE organization_id = o.id AND COALESCE(passed_away, false) = false) as pet_count`;

export function orgUploadDir(subdir) {
  return process.env.ORG_UPLOAD_DIR || path.resolve(process.cwd(), 'uploads', subdir);
}

export function saveOrgImage(file, _orgId, subdir) {
  const dir = orgUploadDir(subdir);
  const fileId = uuidv4();
  const mimeType = validateOrgImageMime(file.mimetype, file.buffer, ORG_IMAGE_EXTENSIONS);
  const { filename } = saveUploadedFile({
    buffer: file.buffer,
    mimeType,
    fileId,
    rootDir: dir,
    allowedExtensions: ORG_IMAGE_EXTENSIONS,
    maxBytes: MAX_ORG_IMAGE_BYTES,
  });
  return `/uploads/${subdir}/${filename}`;
}

export function handleOrgImageUpload(req, res, next) {
  orgImageUpload.single('photo')(req, res, (err) => {
    if (err) {
      if (err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ error: 'Image must be 2 MB or smaller' });
      }
      return res.status(400).json({ error: err.message });
    }
    if (req.file) {
      try {
        req.file.mimetype = validateOrgImageMime(
          req.file.mimetype,
          req.file.buffer,
          ORG_IMAGE_EXTENSIONS,
        );
      } catch (validationErr) {
        return res.status(400).json({ error: validationErr.message });
      }
    }
    next();
  });
}

export async function fetchOrgForUser(pool, userId, orgId) {
  const result = await pool.query(
    `SELECT o.*, ou.role,
      EXISTS(
        SELECT 1 FROM org_foster_parents fp
        WHERE fp.organization_id = o.id
          AND fp.user_id = $1
          AND fp.opt_out_at IS NULL
      ) AS is_foster_parent,
      ${ORG_COUNT_SELECT}
     FROM organizations o
     JOIN organization_users ou ON ou.organization_id = o.id AND ou.user_id = $1
     WHERE o.id = $2`,
    [userId, orgId],
  );
  if (!result.rows.length) return null;
  const row = result.rows[0];
  return orgRowToMap({ ...row, role: normaliseRole(row.role) });
}

export function extractUserId(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  try {
    return jwt.verify(auth.substring(7), JWT_SECRET).id;
  } catch (_) {
    return null;
  }
}

export function safePublicProfileMetadata(raw) {
  if (!raw || typeof raw !== 'object') return {};
  const safe = {};
  for (const key of SAFE_PUBLIC_PROFILE_METADATA_KEYS) {
    const value = raw[key];
    if (value == null || value === '') continue;
    const text = String(value).trim();
    if (text) safe[key] = text;
  }
  return safe;
}

/** Server-computed locality for discovery tiles: postcode → town → administrative_area. */
export function computeDisplayLocality(org) {
  const metadata =
    org.public_profile_metadata && typeof org.public_profile_metadata === 'object'
      ? org.public_profile_metadata
      : {};
  const postcode = String(metadata.postcode ?? '').trim();
  if (postcode) return postcode;
  const town = String(org.town ?? '').trim();
  if (town) return town;
  return String(org.administrative_area ?? '').trim();
}

export function publicOrgRowToMap(row) {
  return {
    id: row.id,
    name: row.name,
    type: row.type || 'professional',
    logo_url: row.logo_url || '',
    photo_url: row.photo_url || '',
    description: row.description || '',
    bio: row.bio || '',
    town: row.town || '',
    administrative_area: row.administrative_area || '',
    public_profile_metadata: safePublicProfileMetadata(row.public_profile_metadata),
    legal_identifier_1: row.legal_identifier_1 || '',
    legal_identifier_2: row.legal_identifier_2 || '',
    legal_identifier_3: row.legal_identifier_3 || '',
    email: row.email || null,
    phone: row.phone || null,
    website: row.website || null,
  };
}

export async function fetchPublicOrg(pool, orgId) {
  const result = await pool.query('SELECT * FROM organizations WHERE id = $1', [orgId]);
  if (!result.rows.length) return null;
  return publicOrgRowToMap(result.rows[0]);
}

export function orgRowToMap(row) {
  return {
    id: row.id,
    name: row.name,
    type: row.type || 'professional',
    email: row.email || null,
    phone: row.phone || null,
    address: row.address || null,
    website: row.website || null,
    bio: row.bio || '',
    photo_url: row.photo_url || '',
    logo_url: row.logo_url || '',
    town: row.town || '',
    administrative_area: row.administrative_area || '',
    description: row.description || '',
    is_discoverable: row.is_discoverable !== false,
    legal_identifier_1: row.legal_identifier_1 || '',
    legal_identifier_2: row.legal_identifier_2 || '',
    legal_identifier_3: row.legal_identifier_3 || '',
    public_profile_metadata:
      row.public_profile_metadata && typeof row.public_profile_metadata === 'object'
        ? row.public_profile_metadata
        : {},
    role: row.role || null,
    is_foster_parent: row.is_foster_parent === true,
    member_count: parseInt(row.member_count, 10) || 0,
    external_count: parseInt(row.external_count, 10) || 0,
    pet_count: parseInt(row.pet_count, 10) || 0,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export async function getMemberRole(pool, orgId, userId) {
  const result = await pool.query(
    'SELECT role FROM organization_users WHERE organization_id = $1 AND user_id = $2',
    [orgId, userId],
  );
  return result.rows.length ? normaliseRole(result.rows[0].role) : null;
}

export async function requireMember(pool, res, orgId, userId) {
  const role = await getMemberRole(pool, orgId, userId);
  if (!isActiveMember(role)) {
    res.status(403).json({ error: 'Forbidden' });
    return null;
  }
  return role;
}

export async function requireOrgAdmin(pool, res, orgId, userId) {
  const role = await getMemberRole(pool, orgId, userId);
  if (!isOrgAdmin(role)) {
    res.status(403).json({ error: 'Forbidden' });
    return null;
  }
  return role;
}

export async function requireSuperAdmin(pool, res, orgId, userId) {
  const role = await getMemberRole(pool, orgId, userId);
  if (!isSuperAdmin(role)) {
    res.status(403).json({ error: 'Forbidden' });
    return null;
  }
  return role;
}

export async function requirePermission(pool, res, orgId, userId, permissionKey) {
  const role = await requireMember(pool, res, orgId, userId);
  if (!role) return null;
  const allowed = await hasPermissionForUser(pool, userId, orgId, permissionKey);
  if (!allowed) {
    res.status(403).json({ error: 'Forbidden' });
    return null;
  }
  return role;
}