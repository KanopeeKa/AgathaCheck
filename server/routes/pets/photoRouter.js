import path from 'path';
import multer from 'multer';
import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { recordPetActivityForPet } from '../../lib/petActivity.js';
import { userCanManagePet } from '../../lib/petAccess.js';
import {
  DEFAULT_MAX_UPLOAD_BYTES,
  extensionForMime,
  normalizeMimeType,
  saveUploadedFile,
  validateOrgImageMime,
} from '../../lib/safeUpload.js';
import { extractUserId } from './shared.js';
import { petRowToMap } from './shared.js';

const PET_PHOTO_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.webp']);
const MAX_PET_PHOTO_BYTES = DEFAULT_MAX_UPLOAD_BYTES;

const petPhotoUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_PET_PHOTO_BYTES },
  fileFilter: (_req, file, cb) => {
    try {
      const normalized = normalizeMimeType(file.mimetype);
      if (!normalized || normalized === 'application/octet-stream') {
        cb(null, true);
        return;
      }
      extensionForMime(normalized, PET_PHOTO_EXTENSIONS);
      file.mimetype = normalized;
      cb(null, true);
    } catch {
      cb(new Error('Only JPG, PNG, and WebP images are allowed'));
    }
  },
});

function petPhotoUploadDir() {
  return process.env.PET_PHOTO_UPLOAD_DIR || path.resolve(process.cwd(), 'uploads', 'pet_photos');
}

function savePetPhoto(file) {
  const fileId = uuidv4();
  const mimeType = validateOrgImageMime(file.mimetype, file.buffer, PET_PHOTO_EXTENSIONS);
  const { filename } = saveUploadedFile({
    buffer: file.buffer,
    mimeType,
    fileId,
    rootDir: petPhotoUploadDir(),
    allowedExtensions: PET_PHOTO_EXTENSIONS,
    maxBytes: MAX_PET_PHOTO_BYTES,
  });
  return `/uploads/pet_photos/${filename}`;
}

function handlePetPhotoUpload(req, res, next) {
  petPhotoUpload.single('photo')(req, res, (err) => {
    if (!err) return next();
    if (err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE') {
      return res.status(413).json({ error: 'Image must be 2 MB or smaller' });
    }
    return res.status(400).json({ error: err.message });
  });
}

export function registerPhotoRoutes(router, pool) {
  router.post('/:id/photo', handlePetPhotoUpload, async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    if (!(await userCanManagePet(pool, id, userId))) {
      return res.status(404).json({ error: 'Pet not found' });
    }
    if (!req.file) {
      return res.status(400).json({ error: 'Photo file is required' });
    }
    try {
      const photoPath = savePetPhoto(req.file);
      const result = await pool.query(
        'UPDATE pets SET photo_path = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
        [photoPath, id],
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      const pet = result.rows[0];
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'pet.photo_updated',
        resourceType: 'pet',
        resourceId: id,
        petId: id,
        orgId: pet.organization_id || null,
        req,
      });
      if (pet.organization_id) {
        recordPetActivityForPet(pool, {
          petId: id,
          actorUserId: userId,
          eventType: 'profile_edit',
          metadata: { field: 'photo' },
        });
      }
      res.status(200).json({
        photoPath,
        pet: petRowToMap(pet),
      });
    } catch (err) {
      res.status(500).json({
        error: publicError(err, 'Photo upload failed', `Photo upload failed: ${err.message}`),
      });
    }
  });
}
